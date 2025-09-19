package cr.ac.itcr.ProyectoLibreria.controller;

import cr.ac.itcr.ProyectoLibreria.service.ServiceTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/service-types")
public class ServiceTypeController {

    @Autowired
    private ServiceTypeService serviceTypeService;
}
