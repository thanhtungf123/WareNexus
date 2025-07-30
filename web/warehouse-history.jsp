<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<html lang="en">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <title>Warehouse History</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: #f4f6f8;
            padding: 20px;
        }

        h2 {
            text-align: center;
            margin-bottom: 30px;
        }

        .card-container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            justify-content: center;
        }

        .warehouse-card {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            padding: 20px;
            width: 300px;
            cursor: pointer;
            transition: transform 0.3s ease;
        }

        .warehouse-card:hover {
            transform: scale(1.03);
        }

        .progress-container {
            display: none;
            flex-wrap: wrap;
            justify-content: space-between;
            align-items: center;
            max-width: 600px;
            margin: 20px auto;
            position: relative;
            padding: 20px 0;
        }

        .progress-step {
            text-align: center;
            flex: 1 1 80px;
            min-width: 60px;
            position: relative;
            z-index: 1;
            transition: all 0.3s ease;
        }

        .step-icon {
            width: 36px;
            height: 36px;
            line-height: 36px;
            border-radius: 50%;
            background: #ccc;
            color: white;
            margin: auto;
            font-size: 18px;
            transition: all 0.3s ease;
        }

        .step-label {
            margin-top: 6px;
            font-size: 12px;
            transition: color 0.3s ease;
        }

        .active .step-icon {
            background: #1976d2;
            transform: scale(1.2);
            box-shadow: 0 0 8px rgba(25, 118, 210, 0.6);
        }

        .active .step-label {
            font-weight: bold;
            color: #1976d2;
        }

        .progress-step:hover .step-icon {
            transform: scale(1.3);
            background: #0d47a1;
        }

        .progress-step:hover .step-label {
            color: #0d47a1;
        }

        .progress-container::before {
            content: '';
            position: absolute;
            top: 36px;
            left: 5%;
            right: 5%;
            height: 4px;
            background: #ccc;
            z-index: 0;
        }

        .progress-fill {
            content: '';
            position: absolute;
            top: 36px;
            left: 5%;
            height: 4px;
            background: #1976d2;
            z-index: 0;
            width: 0;
            transition: width 1s ease;
        }

        .warehouse-card.active {
            border: 2px solid #1976d2;
            box-shadow: 0 0 12px rgba(25, 118, 210, 0.3);
        }
    </style>
    <style>
        .layout-container {
            display: flex;
            gap: 20px;
            align-items: flex-start;
        }

        .left-column {
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .right-column {
            flex: 2;
        }

        .separator {
            width: 2px;
            background: #ccc;
            height: 100%;
            margin: 0 10px;
        }

        .detail-card {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            padding: 16px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
<jsp:include page="header.jsp" />
<div class="layout-container" style="margin-top: 10px; margin-bottom: 10px">
    <div class="left-column">
        <div class="card-container">
            <c:forEach var="order" items="${rentalHistory}">
                <c:set var="warehouse" value="${warehouseMap[order.warehouseID]}" />
                <div class="warehouse-card"
                     onclick="showProgress('${order.rentalOrderID}', '${order.status.toLowerCase()}',
                             '${fn:escapeXml(warehouse.name)}', '${fn:escapeXml(warehouse.address)}, ${fn:escapeXml(warehouse.ward)}, ${fn:escapeXml(warehouse.district)}',
                             '${warehouse.imageUrl}', '${order.startDate}', '${order.endDate}',
                             '${order.deposit}', '${order.totalPrice}', '${order.depositPaid}', '${order.depositRefunded}')">
                    <img src="image?id=${warehouse.imageUrl}" alt="Warehouse Image"
                         style="width:100%; height:180px; object-fit:cover; border-radius:8px; margin-bottom:10px;">
                    <h3>🏢 ${warehouse.name}</h3>
                    <p><strong>Address:</strong> ${warehouse.address}, ${warehouse.ward}, ${warehouse.district}</p>
                    <p><strong>Order Status:</strong> ${order.status}</p>
                </div>
            </c:forEach>
        </div>
    </div>
    <div class="separator"></div>
    <div class="right-column">
        <div class="progress-container" id="progress1">
            <div class="progress-fill"></div>
            <div class="progress-step"><div class="step-icon">⏳</div><div class="step-label">Pending Approval</div></div>
            <div class="progress-step"><div class="step-icon">✅</div><div class="step-label">Approved</div></div>
            <div class="progress-step"><div class="step-icon">💰</div><div class="step-label">Paid</div></div>
            <div class="progress-step"><div class="step-icon">📝</div><div class="step-label">Contract Signed</div></div>
            <div class="progress-step"><div class="step-icon">🎉</div><div class="step-label">Completed</div></div>
        </div>
        <div class="detail-card" id="warehouse-detail" style="display: flex; justify-content: center; align-items: center; text-align: center; flex-direction: column;">
            Warehouse details will appear here when a warehouse is selected.
        </div>
    </div>
</div>
<jsp:include page="footer.jsp" />
<script>
    function showProgress(id, currentStatus, name, address, imageUrl,
                          startDate, endDate, deposit, totalPrice,
                          depositPaid, depositRefunded) {
        const statusOrder = ['pending', 'approved', 'paid', 'contract', 'completed'];
        const statusLabels = {
            pending: '⏳ Pending Approval',
            approved: '✅ Approved',
            paid: '💰 Paid',
            contract: '📝 Contract Signed',
            completed: '🎉 Completed'
        };

        document.querySelectorAll('.progress-container').forEach(p => p.style.display = 'none');
        const container = document.getElementById('progress1');
        container.style.display = 'flex';

        const steps = container.querySelectorAll('.progress-step');
        const fill = container.querySelector('.progress-fill');
        const currentIndex = statusOrder.indexOf(currentStatus);

        steps.forEach((step, index) => {
            step.classList.remove('active');
            if (index <= currentIndex) {
                step.classList.add('active');
            }
        });

        const percent = (currentIndex / (statusOrder.length - 1)) * 90 + 5;
        fill.style.width = percent + '%';
        const detail = document.getElementById('warehouse-detail');
        <%--detail.innerHTML = `--%>
        <%--    <div class="warehouse-card" style="width:100%; max-width:500px; margin-top:20px;">--%>
        <%--        <img src="image?id=${imageUrl}" alt="Warehouse Image"--%>
        <%--             style="width:100%; height:200px; object-fit:cover; border-radius:8px; margin-bottom:10px;">--%>
        <%--        <h3>🏢 ${name}</h3>--%>
        <%--        <p><strong>Address:</strong> ${address}</p>--%>
        <%--        <p><strong>Order Status:</strong> ${statusLabels[currentStatus]}</p>--%>
        <%--        <hr>--%>
        <%--        <p><strong>Rental Period:</strong> ${startDate} → ${endDate}</p>--%>
        <%--        <p><strong>Deposit:</strong> ${deposit} VNĐ</p>--%>
        <%--        <p><strong>Total Price:</strong> ${totalPrice} VNĐ</p>--%>
        <%--        <p><strong>Deposit Paid:</strong> ${depositPaid == 'true' ? '✅ Yes' : '❌ No'}</p>--%>
        <%--        <p><strong>Deposit Refunded:</strong> ${depositRefunded == 'true' ? '✅ Yes' : '❌ No'}</p>--%>
        <%--    </div>--%>
        <%--`;--%>
    }
</script>
</body>
</html>
