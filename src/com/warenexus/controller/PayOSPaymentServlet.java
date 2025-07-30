package com.warenexus.controller;

import com.warenexus.dao.PaymentDAO;
import com.warenexus.dao.RentalOrderDAO;
import com.warenexus.dao.ServiceFeesDAO;
import com.warenexus.dao.WarehouseDAO;
import com.warenexus.model.Payment;
import com.warenexus.model.RentalOrder;
import com.warenexus.util.ConfigUtil;
import com.warenexus.util.PayOSUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import org.json.JSONObject;
import vn.payos.PayOS;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Objects;

@WebServlet("/payos-payment")
public class PayOSPaymentServlet extends HttpServlet {
    private final PaymentDAO paymentDAO = new PaymentDAO();
    private final WarehouseDAO warehouseDAO = new WarehouseDAO();
    private final RentalOrderDAO rentalOrderDAO = new RentalOrderDAO();
    private final ServiceFeesDAO  serviceFeesDAO = new ServiceFeesDAO();
    private static final String CLIENT_ID = ConfigUtil.getProperty("payos.client_id");  // Thay bằng Client ID của bạn
    private static final String API_KEY = ConfigUtil.getProperty("payos.api_key"); // Thay bằng API Key của bạn
    private static final String CHECKSUM_KEY = ConfigUtil.getProperty("payos.checksum_key");  // Thay bằng Checksum Key của bạn
    // Khởi tạo đối tượng PayOS
    private static PayOS payOS;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Lấy từ session
        HttpSession session = req.getSession();
        com.warenexus.model.Account acc = (com.warenexus.model.Account) session.getAttribute("acc");
        String redirectURL = req.getParameter("currentURL");
        if (acc == null) {
            session.setAttribute("redirectAfterLogin", redirectURL);
            resp.sendRedirect("login.jsp");
            return;
        }
        try {
            // 1. Lấy tham số từ form
            int rentalOrderId = Integer.parseInt(req.getParameter("rentalOrderId"));
            double deposit = Double.parseDouble(req.getParameter("deposit"));
            double totalPrice = Double.parseDouble(req.getParameter("totalPrice"));
            String services = req.getParameter("services");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            Date startDate = sdf.parse(startDateStr);
            Date endDate = sdf.parse(endDateStr);
            // Phương thức khởi tạo PayOS

            RentalOrder rentalOrder = rentalOrderDAO.getRentalOrderById(rentalOrderId);

            // 2. Cập nhật Deposit và TotalPrice vào DB
            rentalOrderDAO.updatePriceInfo(rentalOrderId, deposit, totalPrice);
            rentalOrderDAO.updateDates(rentalOrderId, startDate, endDate);

            String[] selectedServices = req.getParameterValues("services");
            if (selectedServices != null) {
                for (String serviceCode : selectedServices) {
                    serviceFeesDAO.insertRentalService(rentalOrderId, serviceCode);
                }
            }

            if (!Objects.equals(rentalOrder.getStatus(), "Approved")) {
                req.getRequestDispatcher("confirmBeforePayment.jsp").forward(req, resp);
                return;
            }

            if (payOS == null) {
                payOS = new PayOS(CLIENT_ID, API_KEY, CHECKSUM_KEY);
            }

            // 3. Tạo request tới PayOS (giả lập hoặc thật)
            String description = "Deposit payment for rental order #" + rentalOrderId;
            String returnUrl = req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort()
                    + req.getContextPath() + "/payos-return?rentalOrderId=" + rentalOrderId + "&status=PAID";

            JSONObject response = PayOSUtil.createPaymentRequest(deposit, description, returnUrl);
            long orderCode = response.getLong("orderCode");
            String qrCode = response.getString("qrCode");
            String paymentLink = response.getString("paymentLink");

            // 4. Lưu thông tin giao dịch vào bảng Payment
            Payment payment = new Payment();
            payment.setRentalOrderID(rentalOrderId);
            payment.setAmount(deposit);
            payment.setStatus("Pending"); // Chờ xác nhận từ PayOS
            payment.setTransactionID(String.valueOf(orderCode));
            payment.setPaymentCategoryID(1); // 1 = Deposit
            payment.setPaymentDate(new Date());

            paymentDAO.insert(payment);


            // 5. Gửi thông tin QR sang trang thanh toán
            req.setAttribute("qrUrl", qrCode);
            req.setAttribute("paymentLink", paymentLink);
            req.setAttribute("rentalOrderId", rentalOrderId);
            req.getRequestDispatcher("paymentQR.jsp").forward(req, resp);

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("error", "Payment initialization failed");
            req.getRequestDispatcher("error.jsp").forward(req, resp);
        }
    }
}
