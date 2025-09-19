package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.service.OrderDetailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/orderdetailst")
public class OrderDetailController {

    @Autowired
    private OrderDetailService orderDetailService;
}
