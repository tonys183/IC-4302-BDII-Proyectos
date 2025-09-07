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

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name1", nullable = false)
    private String lastName1;

    @Column(name = "last_name2")
    private String lastName2;

    @ManyToMany(mappedBy = "authors")
    private Set<Book> books;

    public String getFullName() {
        return firstName + ' ' + lastName1 + ' ' + (lastName2 == null ? "" : lastName2);
    }
}