package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import cr.ac.itcr.ProyectoLibreria.service.AuthorService;
import cr.ac.itcr.ProyectoLibreria.service.BookService;
import cr.ac.itcr.ProyectoLibreria.service.GenreService;
import cr.ac.itcr.ProyectoLibreria.service.PublisherService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/books")
public class BookController {

    @Autowired
    private BookService bookService;
    @Autowired
    private AuthorService authorService;
    @Autowired
    private PublisherService publisherService;
    @Autowired
    private GenreService genreService;

    @GetMapping
    public String listBooks(Model model, Authentication authentication) {
        List<Book> books = bookService.findAll();
        model.addAttribute("books", books);

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/books";
    }

    @GetMapping("/new")
    public String showBookForm(Model model, Authentication authentication) {
        model.addAttribute("book", new Book());
        model.addAttribute("authors", authorService.findAll());
        model.addAttribute("publishers", publisherService.findAll());
        model.addAttribute("genres", genreService.findAll());

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/book-form";
    }

    @PostMapping
    public String saveBook(@ModelAttribute("book") Book book, RedirectAttributes redirectAttributes) {
        try {
            boolean isNew = book.getBookId() == 0;
            bookService.save(book);
            redirectAttributes.addFlashAttribute("message", isNew ? "Libro insertado exitosamente" : "Libro actualizado exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al guardar el libro");
            if (book.getBookId() == 0) {
                return "redirect:/books/new";
            } else {
                return "redirect:/books/edit/" + book.getBookId();
            }
        }
        return "redirect:/books";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Integer id, Model model, Authentication authentication, RedirectAttributes redirectAttributes) {
        try {
            Book book = bookService.findById(id).orElseThrow(() -> new IllegalArgumentException("Invalid book Id:" + id));
            model.addAttribute("book", book);
            model.addAttribute("authors", authorService.findAll());
            model.addAttribute("publishers", publisherService.findAll());
            model.addAttribute("genres", genreService.findAll());
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al obtener el libro para editar");
            return "redirect:/books";
        }

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);

        return "admin/book-form";
    }

    @GetMapping("/delete/{id}")
    public String deleteBook(@PathVariable("id") Integer id, RedirectAttributes redirectAttributes) {
        try {
            bookService.deleteById(id);
            redirectAttributes.addFlashAttribute("message", "Libro eliminado exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al eliminar el libro");
        }
        return "redirect:/books";
    }
}
