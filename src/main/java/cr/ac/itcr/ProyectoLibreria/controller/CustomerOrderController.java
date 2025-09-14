package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.model.*;
import cr.ac.itcr.ProyectoLibreria.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
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
    public String listOrders(Model model) {
        List<CustomerOrder> orders = customerOrderService.findAll();
        model.addAttribute("orders", orders);
        return "orders";
    }

    @GetMapping("/new")
    public String showOrderForm(Model model) {
        model.addAttribute("order", new CustomerOrder());
        model.addAttribute("clients", clientService.findAll());
        model.addAttribute("statuses", statusService.findAll());
        return "order-form";
    }

    @PostMapping
    public String saveOrder(@ModelAttribute("order") CustomerOrder order) {
        if (order.getOrderDate() == null) {
            order.setOrderDate(new Date());
        }
        customerOrderService.save(order);
        return "redirect:/orders";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Integer id, Model model) {
        CustomerOrder order = customerOrderService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Invalid order Id:" + id));
        model.addAttribute("order", order);
        model.addAttribute("clients", clientService.findAll());
        model.addAttribute("statuses", statusService.findAll());
        return "order-form";
    }

    @GetMapping("/delete/{id}")
    public String deleteOrder(@PathVariable("id") Integer id) {
        customerOrderService.deleteById(id);
        return "redirect:/orders";
    }

    @GetMapping("/{id}/details")
    public String showOrderDetails(@PathVariable("id") Integer id, Model model) {
        CustomerOrder order = customerOrderService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Invalid order Id:" + id));
        List<OrderDetail> orderDetails = orderDetailService.findByOrderId(id);
        
        model.addAttribute("order", order);
        model.addAttribute("orderDetails", orderDetails);
        model.addAttribute("books", bookService.findAll());
        model.addAttribute("supplies", supplyService.findAll());
        model.addAttribute("services", serviceService.findAll());
        return "order-details";
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
                .orElseThrow(() -> new IllegalArgumentException("Invalid order Id:" + id));
        
        OrderDetail orderDetail = new OrderDetail();
        orderDetail.setCustomerOrder(order);
        orderDetail.setDateDetail(new Date());
        orderDetail.setQuantity(quantity);
        orderDetail.setUnitPrice(unitPrice);
        
        switch (itemType) {
            case "book":
                if (bookId != null) {
                    Book book = bookService.findById(bookId)
                            .orElseThrow(() -> new IllegalArgumentException("Invalid book Id:" + bookId));
                    orderDetail.setBook(book);
                }
                break;
            case "supply":
                if (supplyId != null) {
                    Supply supply = supplyService.findById(supplyId)
                            .orElseThrow(() -> new IllegalArgumentException("Invalid supply Id:" + supplyId));
                    orderDetail.setSupply(supply);
                }
                break;
            case "service":
                if (serviceId != null) {
                    Service service = serviceService.findById(serviceId)
                            .orElseThrow(() -> new IllegalArgumentException("Invalid service Id:" + serviceId));
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
                                        Model model) {
        CustomerOrder order = customerOrderService.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid order Id:" + orderId));
        OrderDetail orderDetail = orderDetailService.findById(detailId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid order detail Id:" + detailId));
        
        model.addAttribute("order", order);
        model.addAttribute("orderDetail", orderDetail);
        return "order-detail-edit";
    }

    @PostMapping("/{orderId}/details/update/{detailId}")
    public String updateOrderDetail(@PathVariable("orderId") Integer orderId,
                                  @PathVariable("detailId") Integer detailId,
                                  @ModelAttribute("orderDetail") OrderDetail orderDetail) {
        // Usar el método updateQuantity que tiene el trigger
        orderDetailService.updateQuantity(detailId, orderDetail.getQuantity());
        return "redirect:/orders/" + orderId + "/details";
    }

}
