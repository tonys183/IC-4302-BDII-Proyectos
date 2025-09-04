package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "Supply")
public class Supply {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "supply_id")
    private int supplyId;

    @Column(name = "supply_name")
    private String supplyName;

    @Column(name = "stock")
    private int stock;
}