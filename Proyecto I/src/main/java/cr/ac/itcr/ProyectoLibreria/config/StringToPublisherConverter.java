package cr.ac.itcr.ProyectoLibreria.config;

import cr.ac.itcr.ProyectoLibreria.model.Publisher;
import cr.ac.itcr.ProyectoLibreria.repository.PublisherRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;

@Component
public class StringToPublisherConverter implements Converter<String, Publisher> {

    @Autowired
    private PublisherRepository publisherRepository;

    @Override
    public Publisher convert(@NonNull String source) {
        if (source == null || source.isBlank()) {
            return null;
        }
        Integer id = Integer.valueOf(source);
        try {
            return publisherRepository.getReferenceById(id);
        } catch (Exception ignored) {
            Publisher publisher = new Publisher();
            publisher.setPublisherId(id);
            return publisher;
        }
    }
}


