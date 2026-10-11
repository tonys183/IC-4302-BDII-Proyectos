package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "library_user")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private int userId;

    @Column(name = "username", nullable = false, unique = true)
    private String username;

    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "role", nullable = false)
    private String role = "CLIENT";

    public enum UserRole {
        ADMIN("ADMIN"),
        CLIENT("CLIENT");

        private final String value;

        UserRole(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }
    }

    public boolean isAdmin() {
        return UserRole.ADMIN.getValue().equals(this.role);
    }

    public boolean isClient() {
        return UserRole.CLIENT.getValue().equals(this.role);
    }
}