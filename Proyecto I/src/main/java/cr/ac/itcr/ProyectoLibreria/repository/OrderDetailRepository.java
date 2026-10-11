package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, Integer> {

    @Override
    @NonNull
    @Query("SELECT DISTINCT od FROM OrderDetail od LEFT JOIN FETCH od.customerOrder LEFT JOIN FETCH od.supply LEFT JOIN FETCH od.book LEFT JOIN FETCH od.service")
    List<OrderDetail> findAll();

    @Query("SELECT od FROM OrderDetail od LEFT JOIN FETCH od.customerOrder LEFT JOIN FETCH od.supply LEFT JOIN FETCH od.book LEFT JOIN FETCH od.service WHERE od.orderDetailId = :id")
    @NonNull
    Optional<OrderDetail> findById(@NonNull Integer id);

    List<OrderDetail> findByCustomerOrderOrderId(Integer orderId);
}
