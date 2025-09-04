package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BookRepository extends JpaRepository<Book, Integer> {

    @Override
    @Query("SELECT DISTINCT b FROM Book b LEFT JOIN FETCH b.publisher LEFT JOIN FETCH b.authors LEFT JOIN FETCH b.genres")
    List<Book> findAll();

    @Query("SELECT b FROM Book b LEFT JOIN FETCH b.publisher LEFT JOIN FETCH b.authors LEFT JOIN FETCH b.genres WHERE b.bookId = :id")
    Optional<Book> findById(Integer id);
}