package am.lva.auth;

import am.lva.auth.dto.AuthResponse;
import am.lva.auth.dto.LoginRequest;
import am.lva.auth.dto.RegisterRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByPhone(request.phone())) {
            throw new PhoneAlreadyRegisteredException(request.phone());
        }
        var user = new User();
        user.setPhone(request.phone());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(UserRole.CUSTOMER);
        userRepository.save(user);
        return new AuthResponse(
                jwtService.generateToken(user.getId(), user.getRole(), user.getTenantId()),
                user.getRole());
    }

    public AuthResponse login(LoginRequest request) {
        var user = userRepository.findByPhone(request.phone())
                .orElseThrow(InvalidCredentialsException::new);
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }
        return new AuthResponse(
                jwtService.generateToken(user.getId(), user.getRole(), user.getTenantId()),
                user.getRole());
    }
}
