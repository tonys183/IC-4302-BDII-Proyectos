package cr.ac.itcr.ProyectoLibreria.config;

import cr.ac.itcr.ProyectoLibreria.model.Genre;
import cr.ac.itcr.ProyectoLibreria.repository.GenreRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.convert.converter.Converter;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;

@Component
public class StringToGenreConverter implements Converter<String, Genre> {

    @Autowired
    private GenreRepository genreRepository;

    @Override
    public Genre convert(@NonNull String source) {
        if (source == null || source.isBlank()) {
            return null;
        }
        Integer id = Integer.valueOf(source);
        try {
            return genreRepository.getReferenceById(id);
        } catch (Exception ignored) {
            Genre genre = new Genre();
            genre.setGenreId(id);
            return genre;
        }
    }
}


