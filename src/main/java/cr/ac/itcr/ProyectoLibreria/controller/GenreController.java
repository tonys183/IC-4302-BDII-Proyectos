package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.service.GenreService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/genres")
public class GenreController {

    @Autowired
    private GenreService genreService;
}
