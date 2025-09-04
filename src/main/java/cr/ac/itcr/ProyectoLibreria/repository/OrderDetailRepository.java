package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import cr.ac.itcr.ProyectoLibreria.model.OrderDetailId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, OrderDetailId> {
}