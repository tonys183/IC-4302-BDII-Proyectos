package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.CustomerOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerOrderRepository extends JpaRepository<CustomerOrder, Integer> {

    @Override
    @NonNull
    @Query("SELECT DISTINCT co FROM CustomerOrder co LEFT JOIN FETCH co.client LEFT JOIN FETCH co.status LEFT JOIN FETCH co.orderDetails")
    List<CustomerOrder> findAll();

    @Query("SELECT co FROM CustomerOrder co LEFT JOIN FETCH co.client LEFT JOIN FETCH co.status LEFT JOIN FETCH co.orderDetails WHERE co.orderId = :id")
    @NonNull
    Optional<CustomerOrder> findById(@NonNull Integer id);

    List<CustomerOrder> findByClientClientId(int clientId);
}