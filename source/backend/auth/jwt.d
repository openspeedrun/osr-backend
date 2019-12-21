module backend.auth.jwt;
public import vibe.jwt;
import backend.user;

/**
    JWT Auth Info
*/
import backend.user;
static struct JWTAuthInfo {
    Token token;

    User user() {
        return User.getFromJWT(token);
    }

    bool isWebMaster() {
        return user.power == Powers.WebMaster;
    }

    bool isAdmin() {
        return user.power >= Powers.Admin;
    }

    bool isMod() {
        return user.power >= Powers.Mod;
    }

    bool isUser() {
        return user.power >= Powers.User;
    }
}