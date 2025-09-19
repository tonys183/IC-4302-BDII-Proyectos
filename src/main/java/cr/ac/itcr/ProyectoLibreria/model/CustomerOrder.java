package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.*;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;
import java.util.Date;
import java.util.List;

@Data
@Entity
@Table(name = "CustomerOrder")
public class CustomerOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "order_id")
    private int orderId;

    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Column(name = "order_date", nullable = false)
    private Date orderDate;

    @ManyToOne
    @JoinColumn(name = "client_id", nullable = false)
    private Client client;

    @ManyToOne
    @JoinColumn(name = "status_id", nullable = false)
    private Status status;

    @OneToMany(mappedBy = "customerOrder", cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
    private List<OrderDetail> orderDetails;
}