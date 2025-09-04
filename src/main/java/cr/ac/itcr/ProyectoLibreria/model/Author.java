package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.ToString;
import lombok.EqualsAndHashCode;
import java.util.Set;

@Data
@Entity
@ToString(exclude = "books")
@EqualsAndHashCode(exclude = "books")
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