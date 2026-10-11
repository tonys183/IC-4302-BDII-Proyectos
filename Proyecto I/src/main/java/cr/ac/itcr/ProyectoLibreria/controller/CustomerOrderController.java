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
@RequestMapping("/orders")
public class CustomerOrderController {

    @Autowired
    private CustomerOrderService customerOrderService;
    @Autowired
    private ClientService clientService;
    @Autowired
    private StatusService statusService;

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
    public String saveOrder(@ModelAttribute("order") CustomerOrder order, RedirectAttributes redirectAttributes) {
        try {
            boolean isNew = order.getOrderId() == 0;
            customerOrderService.save(order);
            redirectAttributes.addFlashAttribute("message", isNew ? "Orden creada exitosamente" : "Orden actualizada exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al guardar la orden");
            if (order.getOrderId() == 0) {
                return "redirect:/orders/new";
            } else {
                return "redirect:/orders/edit/" + order.getOrderId();
            }
        }
        return "redirect:/orders";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Integer id, Model model, Authentication authentication, RedirectAttributes redirectAttributes) {
        try {
            CustomerOrder order = customerOrderService.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("ID inválido de orden:" + id));
            model.addAttribute("order", order);
            model.addAttribute("clients", clientService.findAll());
            model.addAttribute("statuses", statusService.findAll());
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al obtener la orden para editar");
            return "redirect:/orders";
        }

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "admin/order-form";
    }

    @GetMapping("/delete/{id}")
    public String deleteOrder(@PathVariable("id") Integer id, RedirectAttributes redirectAttributes) {
        try {
            customerOrderService.deleteById(id);
            redirectAttributes.addFlashAttribute("message", "Orden eliminada exitosamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error al eliminar la orden");
        }
        return "redirect:/orders";
    }





}
