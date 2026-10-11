package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "Client")
public class Client {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "client_id")
    private int clientId;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name1", nullable = false)
    private String lastName1;

    @Column(name = "last_name2")
    private String lastName2;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @OneToOne
    @JoinColumn(name = "user_id")
    private User user;

    public String getFullName() {
        return firstName + ' ' + lastName1 + ' ' + (lastName2 == null ? "" : lastName2);
    }
}