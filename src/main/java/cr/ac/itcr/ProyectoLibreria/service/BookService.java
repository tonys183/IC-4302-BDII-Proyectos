package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import cr.ac.itcr.ProyectoLibreria.repository.BookRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class BookService {

    @Autowired
    private BookRepository bookRepository;

    public List<Book> findAll() {
        return bookRepository.findAll();
    }

    public Optional<Book> findById(Integer id) {
        return bookRepository.findById(id);
    }

    public Book save(Book book) {
        return bookRepository.save(book);
    }

    public void deleteById(Integer id) {
        bookRepository.deleteById(id);
    }

    public List<Book> searchBooks(String search) {
        return bookRepository.searchBooks(search);
    }

    public List<Book> findByGenre(String genre) {
        return bookRepository.findByGenre(genre);
    }

    public List<Book> findByAuthor(String author) {
        return bookRepository.findByAuthor(author);
    }
}