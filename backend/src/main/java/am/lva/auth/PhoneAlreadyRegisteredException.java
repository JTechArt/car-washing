package am.lva.auth;

public class PhoneAlreadyRegisteredException extends RuntimeException {
    public PhoneAlreadyRegisteredException(String phone) {
        super("Phone already registered: " + phone);
    }
}
