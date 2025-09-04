package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookRepository extends JpaRepository<Book, Integer> {
}