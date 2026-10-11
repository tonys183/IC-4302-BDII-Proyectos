package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.model.*;
import cr.ac.itcr.ProyectoLibreria.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/orders/{orderId}/details")
public class OrderDetailController {

    @Autowired
    private OrderDetailService orderDetailService;
    @Autowired
    private CustomerOrderService customerOrderService;
    @Autowired
    private BookService bookService;
    @Autowired
    private SupplyService supplyService;
    @Autowired
    private ServiceService serviceService;

    @GetMapping
    public String showOrderDetails(@PathVariable("orderId") Integer orderId, Model model, Authentication authentication) {
        CustomerOrder order = customerOrderService.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + orderId));
        List<OrderDetail> orderDetails = orderDetailService.findByOrderId(orderId);

        model.addAttribute("order", order);
        model.addAttribute("orderDetails", orderDetails);
        model.addAttribute("books", bookService.findAll());
        model.addAttribute("supplies", supplyService.findAll());
        model.addAttribute("services", serviceService.findAll());

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);

        return "admin/order-details";
    }

    @PostMapping
    public String addOrderDetail(@PathVariable("orderId") Integer orderId,
                               @RequestParam("itemType") String itemType,
                               @RequestParam(value = "bookId", required = false) Integer bookId,
                               @RequestParam(value = "supplyId", required = false) Integer supplyId,
                               @RequestParam(value = "serviceId", required = false) Integer serviceId,
                               @RequestParam("quantity") Integer quantity,
                               @RequestParam("unitPrice") Double unitPrice,
                               RedirectAttributes redirectAttributes) {

        try {
            CustomerOrder order = customerOrderService.findById(orderId)
                    .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + orderId));

            OrderDetail orderDetail = new OrderDetail();
            orderDetail.setCustomerOrder(order);
            orderDetail.setQuantity(quantity);
            orderDetail.setUnitPrice(unitPrice);

            switch (itemType) {
                case "book":
                    if (bookId != null) {
                        Book book = bookService.findById(bookId)
                                .orElseThrow(() -> new IllegalArgumentException("ID inválido de libro:" + bookId));
                        orderDetail.setBook(book);
                    }
                    break;
                case "supply":
                    if (supplyId != null) {
                        Supply supply = supplyService.findById(supplyId)
                                .orElseThrow(() -> new IllegalArgumentException("ID inválido de útil:" + supplyId));
                        orderDetail.setSupply(supply);
                    }
                    break;
                case "service":
                    if (serviceId != null) {
                        Service service = serviceService.findById(serviceId)
                                .orElseThrow(() -> new IllegalArgumentException("ID inválido de servicio:" + serviceId));
                        orderDetail.setService(service);
                    }
                    break;
            }

            orderDetailService.save(orderDetail);
            redirectAttributes.addFlashAttribute("message", "Item añadido a la orden exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al añadir el item a la orden");
        }

        return "redirect:/orders/" + orderId + "/details";
    }

    @GetMapping("/delete/{detailId}")
    public String deleteOrderDetail(@PathVariable("orderId") Integer orderId,
                                  @PathVariable("detailId") Integer detailId,
                                  RedirectAttributes redirectAttributes) {
        try {
            orderDetailService.deleteById(detailId);
            redirectAttributes.addFlashAttribute("message", "Item eliminado de la orden exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al eliminar el item de la orden");
        }
        return "redirect:/orders/" + orderId + "/details";
    }

    @GetMapping("/edit/{detailId}")
    public String showEditOrderDetailForm(@PathVariable("orderId") Integer orderId,
                                        @PathVariable("detailId") Integer detailId,
                                        Model model,
                                        Authentication authentication,
                                        RedirectAttributes redirectAttributes) {
        try {
            CustomerOrder order = customerOrderService.findById(orderId)
                    .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + orderId));
            OrderDetail orderDetail = orderDetailService.findById(detailId)
                    .orElseThrow(() -> new IllegalArgumentException("ID inválido de detalle:" + detailId));

            model.addAttribute("order", order);
            model.addAttribute("orderDetail", orderDetail);
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al obtener el detalle para editar");
            return "redirect:/orders/" + orderId + "/details";
        }

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);

        return "admin/order-detail-edit";
    }

    @PostMapping("/update/{detailId}")
    public String updateOrderDetail(@PathVariable("orderId") Integer orderId,
                                    @PathVariable("detailId") Integer detailId,
                                    @ModelAttribute("orderDetail") OrderDetail orderDetail,
                                    RedirectAttributes redirectAttributes) {
        try {
            orderDetailService.updateQuantity(detailId, orderDetail.getQuantity());
            orderDetailService.updateUnitPrice(detailId, orderDetail.getUnitPrice());
            redirectAttributes.addFlashAttribute("message", "Detalle de orden actualizado exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al actualizar el detalle de la orden");
            return "redirect:/orders/" + orderId + "/details/edit/" + detailId;
        }
        return "redirect:/orders/" + orderId + "/details";
    }
}
