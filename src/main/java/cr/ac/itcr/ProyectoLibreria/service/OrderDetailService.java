package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import cr.ac.itcr.ProyectoLibreria.repository.OrderDetailRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
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
    
    public OrderDetail updateQuantity(Integer orderDetailId, Integer newQuantity) {
        // Obtener el username del usuario logueado
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            String username = authentication.getName();
            
            // Guardar el username en la tabla temporal ANTES del update
            try (Connection connection = dataSource.getConnection()) {
                // Limpiar la tabla temporal
                PreparedStatement clearStmt = connection.prepareStatement("DELETE FROM temp_username");
                clearStmt.execute();
                
                // Insertar el username actual
                PreparedStatement insertStmt = connection.prepareStatement(
                    "INSERT INTO temp_username (username) VALUES (?)"
                );
                insertStmt.setString(1, username);
                insertStmt.execute();
            } catch (Exception e) {
                System.err.println("Error setting username in temp table: " + e.getMessage());
            }
        }
        
        // Buscar el OrderDetail y actualizar la quantity
        OrderDetail orderDetail = orderDetailRepository.findById(orderDetailId)
            .orElseThrow(() -> new IllegalArgumentException("OrderDetail no encontrado: " + orderDetailId));
        
        orderDetail.setQuantity(newQuantity);
        return orderDetailRepository.save(orderDetail);
    }

    public void deleteById(Integer id) {
        orderDetailRepository.deleteById(id);
    }

    public List<OrderDetail> findByOrderId(Integer orderId) {
        return orderDetailRepository.findByCustomerOrderOrderId(orderId);
    }
}