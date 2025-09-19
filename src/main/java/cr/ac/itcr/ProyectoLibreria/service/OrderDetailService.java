package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.CustomerOrder;
import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import cr.ac.itcr.ProyectoLibreria.repository.OrderDetailRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.List;
import java.util.Optional;

@Service
public class OrderDetailService {

    @Autowired
    private OrderDetailRepository orderDetailRepository;
    
    
    @Autowired
    private DataSource dataSource;

    public List<OrderDetail> findAll() {
        return orderDetailRepository.findAll();
    }

    public Optional<OrderDetail> findById(Integer id) {
        return orderDetailRepository.findById(id);
    }

    public OrderDetail save(OrderDetail orderDetail) {
        return orderDetailRepository.save(orderDetail);
    }

    public void updateUnitPrice(Integer orderDetailId, Double newUnitPrice) {
        setAdminContext();
        OrderDetail orderDetail = orderDetailRepository.findById(orderDetailId)
                .orElseThrow(() -> new IllegalArgumentException("OrderDetail no encontrado: " + orderDetailId));

        orderDetail.setUnitPrice(newUnitPrice);
        orderDetailRepository.save(orderDetail);
    }

    public void updateQuantity(Integer orderDetailId, Integer newQuantity) {
        setAdminContext();
        
        OrderDetail orderDetail = orderDetailRepository.findById(orderDetailId)
            .orElseThrow(() -> new IllegalArgumentException("OrderDetail no encontrado: " + orderDetailId));
        
        orderDetail.setQuantity(newQuantity);
        orderDetailRepository.save(orderDetail);
    }
    
    private void setAdminContext() {
        try (Connection connection = dataSource.getConnection()) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getAuthorities().stream()
                    .anyMatch(authority -> authority.getAuthority().equals("ROLE_ADMIN"))) {
                
                String username = auth.getName();
                String sql = "SELECT user_id FROM Library_User WHERE username = ? AND role = 'ADMIN'";
                try (var stmt = connection.prepareStatement(sql)) {
                    stmt.setString(1, username);
                    try (var rs = stmt.executeQuery()) {
                        if (rs.next()) {
                            Integer userId = rs.getInt("user_id");
                            
                            String cleanupSql = "DELETE FROM Temp_Admin_Session WHERE created_date < SYSDATE - 1/24";
                            try (var cleanupStmt = connection.prepareStatement(cleanupSql)) {
                                cleanupStmt.executeUpdate();
                            }
                            
                            String upsertSql = "MERGE INTO Temp_Admin_Session a " +
                                             "USING (SELECT ? as username, ? as admin_user_id FROM dual) b " +
                                             "ON (a.username = b.username) " +
                                             "WHEN MATCHED THEN UPDATE SET admin_user_id = b.admin_user_id, created_date = SYSDATE " +
                                             "WHEN NOT MATCHED THEN INSERT (username, admin_user_id) VALUES (b.username, b.admin_user_id)";
                            try (var upsertStmt = connection.prepareStatement(upsertSql)) {
                                upsertStmt.setString(1, username);
                                upsertStmt.setInt(2, userId);
                                upsertStmt.executeUpdate();
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void deleteById(Integer id) {
        setAdminContext();
        OrderDetail orderDetail = orderDetailRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("OrderDetail no encontrado para eliminar: " + id));

        CustomerOrder customerOrder = orderDetail.getCustomerOrder();
        if (customerOrder != null) {
            customerOrder.getOrderDetails().remove(orderDetail);
        }
        orderDetailRepository.delete(orderDetail);
    }


    public List<OrderDetail> findByOrderId(Integer orderId) {
        return orderDetailRepository.findByCustomerOrderOrderId(orderId);
    }
}