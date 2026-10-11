package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.Genre;
import cr.ac.itcr.ProyectoLibreria.repository.GenreRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class GenreService {

    @Autowired
    private GenreRepository repository;

    public List<Genre> findAll() {
        return repository.findAll();
    }
}