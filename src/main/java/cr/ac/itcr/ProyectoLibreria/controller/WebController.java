package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.repository.BookRepository;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WebController {

    private final BookRepository bookRepository;

    public WebController(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/books")
    public String books(Model model) {
        model.addAttribute("books", bookRepository.findAll());
        return "books";
    }
}