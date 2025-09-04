package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "Status")
public class Status {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "status_id")
    private int statusId;

    @Column(name = "status_name")
    private String statusName;
}