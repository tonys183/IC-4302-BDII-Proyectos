package cr.ac.itcr.ProyectoLibreria.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Data;
import java.io.Serializable;
import java.util.Objects;

@Data
@Embeddable
public class OrderDetailId implements Serializable {
    @Column(name = "order_id")
    private int orderId;

    @Column(name = "supply_id")
    private int supplyId;

    @Column(name = "book_id")
    private int bookId;

    @Column(name = "service_id")
    private int serviceId;

    public OrderDetailId() { }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OrderDetailId that = (OrderDetailId) o;
        return orderId == that.orderId && supplyId == that.supplyId && bookId == that.bookId && serviceId == that.serviceId;
    }

    @Override
    public int hashCode() {
        return Objects.hash(orderId, supplyId, bookId, serviceId);
    }
}