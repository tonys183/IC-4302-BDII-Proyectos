package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.model.*;
import cr.ac.itcr.ProyectoLibreria.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Controller
@RequestMapping("/orders")
public class CustomerOrderController {

    @Autowired
    private CustomerOrderService customerOrderService;
    @Autowired
    private ClientService clientService;
    @Autowired
    private StatusService statusService;
    @Autowired
    private OrderDetailService orderDetailService;
    @Autowired
    private BookService bookService;
    @Autowired
    private SupplyService supplyService;
    @Autowired
    private ServiceService serviceService;

    @GetMapping
    public String listOrders(Model model, Authentication authentication) {
        List<CustomerOrder> orders = customerOrderService.findAll();
        model.addAttribute("orders", orders);

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/orders";
    }

    @GetMapping("/new")
    public String showOrderForm(Model model, Authentication authentication) {
        model.addAttribute("order", new CustomerOrder());
        model.addAttribute("clients", clientService.findAll());
        model.addAttribute("statuses", statusService.findAll());

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/order-form";
    }

    @PostMapping
    public String saveOrder(@ModelAttribute("order") CustomerOrder order) {
        customerOrderService.save(order);
        return "redirect:/orders";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Integer id, Model model, Authentication authentication) {
        CustomerOrder order = customerOrderService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + id));
        model.addAttribute("order", order);
        model.addAttribute("clients", clientService.findAll());
        model.addAttribute("statuses", statusService.findAll());

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/order-form";
    }

    @GetMapping("/delete/{id}")
    public String deleteOrder(@PathVariable("id") Integer id) {
        customerOrderService.deleteById(id);
        return "redirect:/orders";
    }

    @GetMapping("/{id}/details")
    public String showOrderDetails(@PathVariable("id") Integer id, Model model, Authentication authentication) {
        CustomerOrder order = customerOrderService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + id));
        List<OrderDetail> orderDetails = orderDetailService.findByOrderId(id);
        
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

    @PostMapping("/{id}/details")
    public String addOrderDetail(@PathVariable("id") Integer id, 
                                @RequestParam("itemType") String itemType,
                                @RequestParam(value = "bookId", required = false) Integer bookId,
                                @RequestParam(value = "supplyId", required = false) Integer supplyId,
                                @RequestParam(value = "serviceId", required = false) Integer serviceId,
                                @RequestParam("quantity") Integer quantity,
                                @RequestParam("unitPrice") Double unitPrice) {
        
        CustomerOrder order = customerOrderService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + id));
        
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
        return "redirect:/orders/" + id + "/details";
    }

    @GetMapping("/{orderId}/details/delete/{detailId}")
    public String deleteOrderDetail(@PathVariable("orderId") Integer orderId, 
                                   @PathVariable("detailId") Integer detailId) {
        orderDetailService.deleteById(detailId);
        return "redirect:/orders/" + orderId + "/details";
    }

    @GetMapping("/{orderId}/details/edit/{detailId}")
    public String showEditOrderDetailForm(@PathVariable("orderId") Integer orderId,
                                        @PathVariable("detailId") Integer detailId,
                                        Model model, Authentication authentication) {
        CustomerOrder order = customerOrderService.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + orderId));
        OrderDetail orderDetail = orderDetailService.findById(detailId)
                .orElseThrow(() -> new IllegalArgumentException("ID inválido de detalle:" + detailId));
        
        model.addAttribute("order", order);
        model.addAttribute("orderDetail", orderDetail);

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/order-detail-edit";
    }

    @PostMapping("/{orderId}/details/update/{detailId}")
    public String updateOrderDetail(@PathVariable("orderId") Integer orderId,
                                  @PathVariable("detailId") Integer detailId,
                                  @ModelAttribute("orderDetail") OrderDetail orderDetail) {
        orderDetailService.updateQuantity(detailId, orderDetail.getQuantity());
        return "redirect:/orders/" + orderId + "/details";
    }

}
