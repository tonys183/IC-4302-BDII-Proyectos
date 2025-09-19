package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.model.Book;
import cr.ac.itcr.ProyectoLibreria.model.Client;
import cr.ac.itcr.ProyectoLibreria.model.CustomerOrder;
import cr.ac.itcr.ProyectoLibreria.model.OrderDetail;
import cr.ac.itcr.ProyectoLibreria.model.Service;
import cr.ac.itcr.ProyectoLibreria.model.ServiceType;
import cr.ac.itcr.ProyectoLibreria.model.Supply;
import cr.ac.itcr.ProyectoLibreria.service.BookService;
import cr.ac.itcr.ProyectoLibreria.service.ClientService;
import cr.ac.itcr.ProyectoLibreria.service.CustomerOrderService;
import cr.ac.itcr.ProyectoLibreria.service.OrderDetailService;
import cr.ac.itcr.ProyectoLibreria.service.ServiceService;
import cr.ac.itcr.ProyectoLibreria.service.ServiceTypeService;
import cr.ac.itcr.ProyectoLibreria.service.StatusService;
import cr.ac.itcr.ProyectoLibreria.service.SupplyService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import jakarta.servlet.http.HttpSession;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/catalog")
public class ClientController {

    private final BookService bookService;
    private final CustomerOrderService customerOrderService;
    private final ClientService clientService;
    private final OrderDetailService orderDetailService;
    private final ServiceService serviceService;
    private final ServiceTypeService serviceTypeService;
    private final SupplyService supplyService;

    public ClientController(BookService bookService, CustomerOrderService customerOrderService, 
                           ClientService clientService, OrderDetailService orderDetailService,
                           ServiceService serviceService, ServiceTypeService serviceTypeService,
                           StatusService statusService, SupplyService supplyService) {
        this.bookService = bookService;
        this.customerOrderService = customerOrderService;
        this.clientService = clientService;
        this.orderDetailService = orderDetailService;
        this.serviceService = serviceService;
        this.serviceTypeService = serviceTypeService;
        this.supplyService = supplyService;
    }

    @GetMapping
    public String catalog(Model model, 
                         @RequestParam(required = false) String search,
                         @RequestParam(required = false) String genre,
                         @RequestParam(required = false) String author,
                         @RequestParam(required = false, defaultValue = "books") String type,
                         Authentication authentication) {

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));

        List<ServiceType> serviceTypes = serviceTypeService.findAll();

        if ("services".equals(type)) {
            List<Service> services = serviceService.findAll();
            model.addAttribute("services", services);
            model.addAttribute("currentType", "services");
        } else if ("supplies".equals(type)) {
            List<Supply> supplies = supplyService.findAll();
            model.addAttribute("supplies", supplies);
            model.addAttribute("currentType", "supplies");
        } else {
            List<Book> books;
            
            if (search != null && !search.trim().isEmpty()) {
                books = bookService.searchBooks(search);
            } else if (genre != null && !genre.trim().isEmpty()) {
                books = bookService.findByGenre(genre);
            } else if (author != null && !author.trim().isEmpty()) {
                books = bookService.findByAuthor(author);
            } else {
                books = bookService.findAll();
            }
            
            model.addAttribute("books", books);
            model.addAttribute("currentType", "books");
        }
        
        model.addAttribute("search", search);
        model.addAttribute("genre", genre);
        model.addAttribute("author", author);
        model.addAttribute("type", type);
        model.addAttribute("serviceTypes", serviceTypes);
        model.addAttribute("isAdmin", isAdmin);
        
        return "client/catalog";
    }

    @GetMapping("/my-orders")
    public String myOrders(Model model, Authentication authentication) {
        try {
            String username = authentication.getName();
            Client client = clientService.findByUsername(username);
            
            List<CustomerOrder> orders;
            if (client != null) {
                orders = customerOrderService.findByClientId(client.getClientId());
            } else {
                orders = List.of();
            }
            
            model.addAttribute("orders", orders);
            model.addAttribute("username", username);
        } catch (Exception e) {
            model.addAttribute("orders", List.of());
            model.addAttribute("username", authentication != null ? authentication.getName() : "Usuario");
        }
        
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "client/my-orders";
    }

    @GetMapping("/create-order")
    public String createOrder(Model model, HttpSession session, Authentication authentication) {
        List<OrderDetail> orderItems = (List<OrderDetail>) session.getAttribute("orderItems");
        if (orderItems == null) {
            orderItems = new ArrayList<>();
        }
        
        List<Book> books = bookService.findAll();
        model.addAttribute("books", books);
        model.addAttribute("orderItems", orderItems);
        
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        model.addAttribute("isAdmin", isAdmin);
        
        return "client/create-order";
    }

    @GetMapping("/search")
    public String searchBooks(Model model, 
                             @RequestParam(required = false) String search,
                             @RequestParam(required = false) String genre,
                             @RequestParam(required = false) String author,
                             @RequestParam(required = false, defaultValue = "books") String type,
                             Authentication authentication) {

        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));

        if ("books".equals(type)) {
            List<Book> books;
            
            if (search != null && !search.trim().isEmpty()) {
                books = bookService.searchBooks(search);
            } else if (genre != null && !genre.trim().isEmpty()) {
                books = bookService.findByGenre(genre);
            } else if (author != null && !author.trim().isEmpty()) {
                books = bookService.findByAuthor(author);
            } else {
                books = bookService.findAll();
            }
            
            model.addAttribute("books", books);
            model.addAttribute("currentType", "books");
        }
        
        model.addAttribute("isAdmin", isAdmin);
        
        return "client/catalog :: #books-results";
    }

    @PostMapping("/add-to-order")
    public String addToOrder(@RequestParam(required = false) Integer bookId,
                           @RequestParam(required = false) Integer serviceId,
                           @RequestParam(required = false) Integer supplyId,
                           @RequestParam String itemType,
                           @RequestParam int quantity,
                           HttpSession session) {
        
        List<OrderDetail> orderItems = (List<OrderDetail>) session.getAttribute("orderItems");
        if (orderItems == null) {
            orderItems = new ArrayList<>();
        }
        
        OrderDetail item = new OrderDetail();
        item.setQuantity(quantity);
        
        if ("book".equals(itemType) && bookId != null) {
            Book book = bookService.findById(bookId).orElse(null);
            if (book != null) {
                item.setBook(book);
                item.setUnitPrice(book.getPrice());
                orderItems.add(item);
            }
        } else if ("service".equals(itemType) && serviceId != null) {
            Service service = serviceService.findById(serviceId).orElse(null);
            if (service != null) {
                item.setService(service);
                item.setUnitPrice(service.getPrice());
                orderItems.add(item);
            }
        } else if ("supply".equals(itemType) && supplyId != null) {
            Supply supply = supplyService.findById(supplyId).orElse(null);
            if (supply != null) {
                item.setSupply(supply);
                item.setUnitPrice(supply.getPrice());
                orderItems.add(item);
            }
        }
        
        session.setAttribute("orderItems", orderItems);
        return "redirect:/catalog/create-order";
    }

    @GetMapping("/remove-from-order")
    public String removeFromOrder(@RequestParam int itemId, HttpSession session) {
        List<OrderDetail> orderItems = (List<OrderDetail>) session.getAttribute("orderItems");
        if (orderItems != null && itemId < orderItems.size()) {
            orderItems.remove(itemId);
            session.setAttribute("orderItems", orderItems);
        }
        return "redirect:/catalog/create-order";
    }

    @GetMapping("/finalize-order")
    public String finalizeOrder(HttpSession session, Authentication authentication) {
        List<OrderDetail> orderItems = (List<OrderDetail>) session.getAttribute("orderItems");
        
        if (orderItems != null && !orderItems.isEmpty()) {
            try {
                Client client = clientService.findByUsername(authentication.getName());
                
                CustomerOrder order = new CustomerOrder();
                order.setClient(client);
                
                CustomerOrder savedOrder = customerOrderService.save(order);
                
                for (OrderDetail item : orderItems) {
                    item.setCustomerOrder(savedOrder);
                    OrderDetail savedItem = orderDetailService.save(item);
                }
                
                session.removeAttribute("orderItems");
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else {
            session.removeAttribute("orderItems");
        }
        
        return "redirect:/catalog/my-orders";
    }

    @GetMapping("/order-details/{id}")
    public String orderDetails(@PathVariable int id, Model model, Authentication authentication) {
        try {
            String username = authentication.getName();
            Client client = clientService.findByUsername(username);
            
            CustomerOrder order = customerOrderService.findById(id).orElse(null);

            if (order != null && order.getClient().getClientId() == client.getClientId()) {
                model.addAttribute("order", order);
                
                boolean isAdmin = authentication.getAuthorities().stream()
                        .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
                model.addAttribute("isAdmin", isAdmin);
                
                return "client/order-details";
            } else {
                return "redirect:/catalog/my-orders";
            }
        } catch (Exception e) {
            return "redirect:/catalog/my-orders";
        }
    }
}
