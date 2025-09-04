package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.ServiceType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ServiceTypeRepository extends JpaRepository<ServiceType, Integer> {
}