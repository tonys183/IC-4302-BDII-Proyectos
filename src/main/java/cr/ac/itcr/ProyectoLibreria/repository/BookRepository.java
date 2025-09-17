package cr.ac.itcr.ProyectoLibreria.repository;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    @Query("SELECT DISTINCT b FROM Book b LEFT JOIN FETCH b.publisher LEFT JOIN FETCH b.authors LEFT JOIN FETCH b.genres " +
           "WHERE LOWER(b.bookName) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(b.isbn) LIKE LOWER(CONCAT('%', :search, '%'))")
    List<Book> searchBooks(@Param("search") String search);

    @Query("SELECT DISTINCT b FROM Book b LEFT JOIN FETCH b.publisher LEFT JOIN FETCH b.authors LEFT JOIN FETCH b.genres " +
           "JOIN b.genres g WHERE LOWER(g.genreName) LIKE LOWER(CONCAT('%', :genre, '%'))")
    List<Book> findByGenre(@Param("genre") String genre);

    @Query("SELECT DISTINCT b FROM Book b LEFT JOIN FETCH b.publisher LEFT JOIN FETCH b.authors LEFT JOIN FETCH b.genres " +
           "JOIN b.authors a WHERE LOWER(a.firstName) LIKE LOWER(CONCAT('%', :author, '%')) OR " +
           "LOWER(a.lastName1) LIKE LOWER(CONCAT('%', :author, '%')) OR " +
           "LOWER(a.lastName2) LIKE LOWER(CONCAT('%', :author, '%'))")
    List<Book> findByAuthor(@Param("author") String author);
}