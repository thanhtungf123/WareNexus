package com.warenexus.controller;

import com.warenexus.dao.RentalOrderDAO;
import com.warenexus.dao.WarehouseDAO;
import com.warenexus.model.Account;
import com.warenexus.model.RentalOrder;

import com.warenexus.model.Warehouse;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/warehouse-history")
public class WarehouseHistoryController extends HttpServlet {
    private final RentalOrderDAO rentalOrderDAO = new RentalOrderDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Account user = (Account) session.getAttribute("user");

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            //Lấy danh sách đơn thuê kho của người dùng
            List<RentalOrder> historyList = rentalOrderDAO.getRentalOrderByAccountID(user.getAccountId());
            Map<Integer, Warehouse> warehouseMap = new HashMap<>();
            WarehouseDAO warehouseDAO = new WarehouseDAO();

            for (RentalOrder order : historyList) {
                Warehouse wh = warehouseDAO.getById(order.getWarehouseID());
                warehouseMap.put(order.getWarehouseID(), wh);
            }

            request.setAttribute("warehouseMap", warehouseMap);
            // Gửi danh sách sang JSP để hiển thị
            request.setAttribute("rentalHistory", historyList);
            request.getRequestDispatcher("warehouse-history.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("error.jsp");
        }
    }
}
