package cr.ac.itcr.ProyectoLibreria.config;

import cr.ac.itcr.ProyectoLibreria.model.Author;
import cr.ac.itcr.ProyectoLibreria.repository.AuthorRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;

@Component
public class StringToAuthorConverter implements Converter<String, Author> {

    @Autowired
    private AuthorRepository authorRepository;

    @Override
    public Author convert(@NonNull String source) {
        if (source == null || source.isBlank()) {
            return null;
        }
        Long id = Long.valueOf(source);
        try {
            return authorRepository.getReferenceById(id);
        } catch (Exception ignored) {
            Author author = new Author();
            author.setAuthor_id(id);
            return author;
        }
    }
}


