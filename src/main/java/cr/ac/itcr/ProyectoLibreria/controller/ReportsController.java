package cr.ac.itcr.ProyectoLibreria.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/admin/reports")
public class ReportsController {

    @Autowired
    private DataSource dataSource;

    @GetMapping
    public String reports(Model model, Authentication authentication) {
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        
        if (!isAdmin) {
            return "redirect:/";
        }

        model.addAttribute("isAdmin", isAdmin);
        return "admin/reports";
    }

    @GetMapping("/high-spending-clients")
    public String highSpendingClients(Model model, Authentication authentication) {
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        
        if (!isAdmin) {
            return "redirect:/";
        }

        List<Map<String, Object>> results = new ArrayList<>();
        
        try (Connection connection = dataSource.getConnection()) {
            String sql = "SELECT (c.first_name || ' ' || c.last_name1) AS nombre_completo, s.supply_name, od.quantity, (od.quantity * od.unit_price) AS total_detalle " +
                        "FROM OrderDetail od " +
                        "INNER JOIN Supply s ON od.supply_id = s.supply_id " +
                        "INNER JOIN CustomerOrder o ON od.order_id = o.order_id " +
                        "INNER JOIN Client c ON o.client_id = c.client_id " +
                        "WHERE (od.quantity * od.unit_price) >= 2000 AND od.supply_id IS NOT NULL";
            
            try (PreparedStatement stmt = connection.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("Cliente", rs.getString("nombre_completo"));
                    row.put("Suministro", rs.getString("supply_name"));
                    row.put("Cantidad", rs.getInt("quantity"));
                    row.put("Total", rs.getDouble("total_detalle"));
                    results.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        model.addAttribute("results", results);
        model.addAttribute("isAdmin", isAdmin);
        return "admin/reports";
    }

    @GetMapping("/client-books")
    public String clientBooks(Model model, Authentication authentication) {
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        
        if (!isAdmin) {
            return "redirect:/";
        }

        List<Map<String, Object>> results = new ArrayList<>();
        
        try (Connection connection = dataSource.getConnection()) {
            String sql = "SELECT (c.first_name || ' ' || c.last_name1) AS nombre_completo, COUNT(od.book_id) AS libros_comprados " +
                        "FROM OrderDetail od " +
                        "RIGHT JOIN CustomerOrder o ON od.order_id = o.order_id AND od.book_id IS NOT NULL " +
                        "RIGHT JOIN Client c ON o.client_id = c.client_id " +
                        "GROUP BY c.client_id, c.first_name, c.last_name1";
            
            try (PreparedStatement stmt = connection.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("Cliente", rs.getString("nombre_completo"));
                    row.put("Libros Comprados", rs.getInt("libros_comprados"));
                    results.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        model.addAttribute("results", results);
        model.addAttribute("isAdmin", isAdmin);
        return "admin/reports";
    }

    @GetMapping("/book-sales")
    public String bookSales(Model model, Authentication authentication) {
        boolean isAdmin = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
        
        if (!isAdmin) {
            return "redirect:/";
        }

        List<Map<String, Object>> results = new ArrayList<>();
        
        try (Connection connection = dataSource.getConnection()) {
            String sql = "SELECT b.book_name, (a.first_name || ' ' || a.last_name1 || ' ' || NVL(a.last_name2, '')) AS autor_completo, b.ISBN, p.publisher_name, COUNT(od.book_id) AS libros_vendidos " +
                        "FROM Book b " +
                        "LEFT JOIN OrderDetail od ON b.book_id = od.book_id " +
                        "LEFT JOIN Book_Author ba ON b.book_id = ba.book_id " +
                        "LEFT JOIN Author a ON ba.author_id = a.author_id " +
                        "LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id " +
                        "GROUP BY b.book_id, b.book_name, b.ISBN, a.first_name, a.last_name1, a.last_name2, p.publisher_name " +
                        "ORDER BY libros_vendidos DESC";
            
            try (PreparedStatement stmt = connection.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("Título del Libro", rs.getString("book_name"));
                    row.put("Autor", rs.getString("autor_completo"));
                    row.put("ISBN", rs.getString("ISBN"));
                    row.put("Editorial", rs.getString("publisher_name"));
                    row.put("Libros Vendidos", rs.getInt("libros_vendidos"));
                    results.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        model.addAttribute("results", results);
        model.addAttribute("isAdmin", isAdmin);
        return "admin/reports";
    }
}
