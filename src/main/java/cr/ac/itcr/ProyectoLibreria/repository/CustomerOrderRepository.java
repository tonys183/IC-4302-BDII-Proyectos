package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.CustomerOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerOrderRepository extends JpaRepository<CustomerOrder, Integer> {
}