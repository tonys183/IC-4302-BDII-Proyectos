package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.ServiceType;
import cr.ac.itcr.ProyectoLibreria.repository.ServiceTypeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ServiceTypeService {

    @Autowired
    private ServiceTypeRepository serviceTypeRepository;

    public List<ServiceType> findAll() {
        return serviceTypeRepository.findAll();
    }

    public Optional<ServiceType> findById(Integer id) {
        return serviceTypeRepository.findById(id);
    }

    public ServiceType save(ServiceType serviceType) {
        return serviceTypeRepository.save(serviceType);
    }

    public void deleteById(Integer id) {
        serviceTypeRepository.deleteById(id);
    }
}