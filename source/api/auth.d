module api.auth;
import backend.registrations;
import api.common;
import backend.user;
import config;

enum AUTH_FAIL_MSG = "Invalid username or password";
enum AUTH_VER_FAIL_MSG = "This account hasn't been verified, please check your email. (Even the spam folder)";

enum REG_EMPTY_UNAME = "Username can not be empty";
enum REG_EMPTY_PASSWD = "Password can not be empty";
enum REG_EMPTY_EMAIL = "Email can not be empty";
enum REG_EMAIL_INVALID = "Invalid email address";
enum REG_TAKEN = "Username or Email taken";
enum REG_RC_SCORE = "Spam bots not allowed.";
enum REG_CREATE_ERROR = "User could not be created for unknown reason. Please contact the developers.";
enum REG_DISABLED = "User registrations have been disabled.";

/++
    Endpoint for user managment
+/
@path("/auth")
interface IAuthenticationEndpoint {

    /++
        Logs in as bot account
    +/
    @method(HTTPMethod.POST)
    @path("/login/bot")
    Token login(string authToken);


    /++
        Logs in as user account
    +/
    @method(HTTPMethod.POST)
    @path("/login/user")
    @bodyParam("username", "username")
    @bodyParam("password", "password")
    Token login(string username, string password);

    /++
        Register a new account

        returns ok_verify if account needs email verification
        returns a token if the account is verified and ready
    +/
    @method(HTTPMethod.POST)
    @path("/register")
    @bodyParam("username", "username")
    @bodyParam("email", "email")
    @bodyParam("password", "password")
    @bodyParam("rcToken", "rcToken")
    string register(string username, string email, string password, string rcToken);

    /**
        Gets wether the site is allowing registrations
    */
    @method(HTTPMethod.GET)
    @path("/regstatus")
    bool registrationOpen();

    /++
        Verifies a new user allowing them to create/post runs, etc.
    +/
    @method(HTTPMethod.POST)
    @path("/verify")
    @bodyParam("verifykey")
    string verify(string verifykey);

    /++
        Gets the status of a user's JWT token
    +/
    @method(HTTPMethod.POST)
    @path("/status")
    string getUserStatus(JWTAuthInfo token);


    /++
        Gets the rechapta site key.
    +/
    @path("/siteKey")
    @method(HTTPMethod.GET)
    string siteKey();
}

/++
    Implementation of auth endpoint
+/
@requiresAuth
class AuthenticationEndpoint : IAuthenticationEndpoint {
private:
    string createToken(User user) {
        import vibe.data.json : serializeToJson, Json;
        JWTToken token;
        token.header.algorithm = JWTAlgorithm.HS512;
        token.payload = Json.emptyObject();
        token.payload["username"] = user.username;

        // TODO: Make token expire.

        token.sign();

        return token.toString();
    }

public:

    mixin implemementJWT;

    /// Login (bot)
    @noAuth
    Token login(string secret) {

        // Get user instance
        User userPtr = User.getFromSecret(secret);

        // If user doesn't exist, make error
        if (userPtr is null) throw new HTTPStatusException(404, AUTH_FAIL_MSG);

        // If user hasn't verified their email (and such is turned on), make error
        if (CONFIG.auth.emailVerification && !userPtr.verified) throw new HTTPStatusException(400, AUTH_VER_FAIL_MSG);

        // Start new session via JWT token
        return createToken(userPtr);
    }

    /// Login (user)
    @noAuth
    Token login(string username, string password) {

        // Get user instance
        User userPtr = User.get(username);

        // If user doesn't exist, make error
        if (userPtr is null) throw new HTTPStatusException(HTTPStatus.unauthorized, AUTH_FAIL_MSG);

        // If user hasn't verified their email (and such is turned on), make error
        if (CONFIG.auth.emailVerification && !userPtr.verified) throw new HTTPStatusException(HTTPStatus.internalServerError, AUTH_VER_FAIL_MSG);

        // If the password isn't correct, make error
        if (!userPtr.auth.verify(password)) throw new HTTPStatusException(HTTPStatus.unauthorized, AUTH_FAIL_MSG);

        // Start new session via JWT token
        return createToken(userPtr);
    }

    /// Register
    @noAuth
    string register(string username, string email, string password, string rcToken) {
        import vibe.utils.validation : validateEmail;

        if (!CONFIG.auth.allowSignups) throw new HTTPStatusException(HTTPStatus.badRequest, REG_DISABLED);

        /*
            The big block of validation
        */

        if (User.get(username) !is null || User.get(email) !is null) {
            throw new HTTPStatusException(HTTPStatus.badRequest, REG_TAKEN);
        }

        if (username.length == 0) throw new HTTPStatusException(HTTPStatus.badRequest, REG_EMPTY_UNAME);
        if (email.length == 0) throw new HTTPStatusException(HTTPStatus.badRequest, REG_EMPTY_EMAIL);
        if (password.length == 0) throw new HTTPStatusException(HTTPStatus.badRequest, REG_EMPTY_PASSWD);
        
        // Email validation
        try {
            validateEmail(email, 128);
        } catch (Exception) {
            throw new HTTPStatusException(HTTPStatus.badRequest, REG_EMAIL_INVALID);
        }

        User user;

        // Make sure the account gets created
        try {
            user = User.register(username, email, password);
            if (user is null) {
                throw new HTTPStatusException(HTTPStatus.internalServerError, REG_CREATE_ERROR);
            }
        } catch(HTTPStatusException ex) {
            throw ex;
        } catch(Exception ex) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, ex.msg);
        }
        
        // Return ok_verify if the user needs to verify their email, return ok if already verified
        if (CONFIG.auth.emailVerification) return "ok_verify";
        return createToken(user);
    }

    /// Check wether registrations are open
    @noAuth
    bool registrationOpen() {
        return CONFIG.auth.allowSignups;
    }

    @noAuth
    string siteKey() {
        return CONFIG.auth.recaptchaSiteKey;
    }

    /// Verify user
    @noAuth
    string verify(string verifykey) {
        if (Registration.verifyUser(verifykey)) return StatusCode.StatusOK;
        throw new HTTPStatusException(HTTPStatus.unauthorized);
    }

    @auth(Role.User)
    string getUserStatus(JWTAuthInfo token) {
        return User.getValidFromJWT(token.token) ? StatusCode.StatusOK : StatusCode.StatusInvalid;
    }
}