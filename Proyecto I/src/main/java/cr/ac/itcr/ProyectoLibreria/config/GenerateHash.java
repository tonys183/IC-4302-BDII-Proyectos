package cr.ac.itcr.ProyectoLibreria.config;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class GenerateHash {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        System.out.println(encoder.encode("1"));
        System.out.println(encoder.encode("12"));
        System.out.println(encoder.encode("123"));
        System.out.println(encoder.encode("1234"));
        System.out.println(encoder.encode("12345"));
        System.out.println(encoder.encode("123456"));
        System.out.println(encoder.encode("1234567"));
        System.out.println(encoder.encode("12345678"));
        System.out.println(encoder.encode("123456789"));
        System.out.println(encoder.encode("1234567890"));
    }
}
