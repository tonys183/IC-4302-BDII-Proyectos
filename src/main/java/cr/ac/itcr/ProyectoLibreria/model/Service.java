package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "Service")
public class Service {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "service_id")
    private int serviceId;

    @Column(name = "service_name")
    private String serviceName;

    @ManyToOne
    @JoinColumn(name = "type_id")
    private ServiceType type;
}