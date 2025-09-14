package cr.ac.itcr.ProyectoLibreria.service;

import cr.ac.itcr.ProyectoLibreria.model.Supply;
import cr.ac.itcr.ProyectoLibreria.repository.SupplyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class SupplyService {

    @Autowired
    private SupplyRepository supplyRepository;

    public List<Supply> findAll() {
        return supplyRepository.findAll();
    }

    public Optional<Supply> findById(Integer id) {
        return supplyRepository.findById(id);
    }

    public Supply save(Supply supply) {
        return supplyRepository.save(supply);
    }

    public void deleteById(Integer id) {
        supplyRepository.deleteById(id);
    }
}