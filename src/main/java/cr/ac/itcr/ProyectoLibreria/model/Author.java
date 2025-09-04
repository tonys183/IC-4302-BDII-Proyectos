package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;
import java.util.Set;

@Data
@Entity
@Table(name = "Author")
public class Author {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "author_id")
    private long author_id;

    @Column(name = "author_name")
    private String author_name;

    @ManyToMany(mappedBy = "authors")
    private Set<Book> books;
}