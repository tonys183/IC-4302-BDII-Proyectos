package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import cr.ac.itcr.ProyectoLibreria.model.Supply;
import cr.ac.itcr.ProyectoLibreria.repository.OrderDetailRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.util.List;
import java.util.Optional;

@Service
public class OrderDetailService {

    @Autowired
    private OrderDetailRepository orderDetailRepository;
    
    @Autowired
    private SupplyService supplyService;
    
    @Autowired
    private DataSource dataSource;

    public List<OrderDetail> findAll() {
        return orderDetailRepository.findAll();
    }

    public Optional<OrderDetail> findById(Integer id) {
        return orderDetailRepository.findById(id);
    }

    public OrderDetail save(OrderDetail orderDetail) {
        if (orderDetail.getSupply() != null) {
            Supply supply = orderDetail.getSupply();
            if (supply.getStock() < orderDetail.getQuantity()) {
                throw new IllegalArgumentException("Stock insuficiente.");
            }
            if (supply.getStock() == 0) {
                throw new IllegalArgumentException("El producto está agotado");
            }
        }
        
        OrderDetail savedOrderDetail = orderDetailRepository.save(orderDetail);
        
        if (orderDetail.getSupply() != null) {
            Supply supply = orderDetail.getSupply();
            supply.setStock(supply.getStock() - orderDetail.getQuantity());
            supplyService.save(supply);
        }
        
        return savedOrderDetail;
    }
    
    public void updateQuantity(Integer orderDetailId, Integer newQuantity) {
        setAdminContext();
        
        OrderDetail orderDetail = orderDetailRepository.findById(orderDetailId)
            .orElseThrow(() -> new IllegalArgumentException("OrderDetail no encontrado: " + orderDetailId));
        
        Integer oldQuantity = orderDetail.getQuantity();
        Integer quantityDifference = newQuantity - oldQuantity;
        
        if (orderDetail.getSupply() != null && quantityDifference > 0) {
            Supply supply = orderDetail.getSupply();
            if (supply.getStock() < quantityDifference) {
                throw new IllegalArgumentException("Stock insuficiente.");
            }
        }
        
        orderDetail.setQuantity(newQuantity);
        orderDetailRepository.save(orderDetail);
        
        if (quantityDifference != 0) {
            updateStock(orderDetail, quantityDifference);
        }
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
                            String callSql = "CALL set_admin_context(?)";
                            try (CallableStatement callStmt = connection.prepareCall(callSql)) {
                                callStmt.setInt(1, userId);
                                callStmt.execute();
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private void updateStock(OrderDetail orderDetail, Integer quantityDifference) {
        if (orderDetail.getSupply() != null) {
            Supply supply = orderDetail.getSupply();
            supply.setStock(supply.getStock() - quantityDifference);
            supplyService.save(supply);
        }
    }

    public void deleteById(Integer id) {
        orderDetailRepository.deleteById(id);
    }

    public List<OrderDetail> findByOrderId(Integer orderId) {
        return orderDetailRepository.findByCustomerOrderOrderId(orderId);
    }
}