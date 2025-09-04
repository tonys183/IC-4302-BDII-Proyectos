package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.Supply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SupplyRepository extends JpaRepository<Supply, Integer> {
}