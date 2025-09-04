package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.Publisher;
import cr.ac.itcr.ProyectoLibreria.repository.PublisherRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PublisherService {

    @Autowired
    private PublisherRepository repository;

    public List<Publisher> findAll() {
        return repository.findAll();
    }
}