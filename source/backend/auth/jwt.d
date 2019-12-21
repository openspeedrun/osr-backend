module backend.auth.jwt;
import backend.common : generateIDArr;
import secured.mac;
import vibe.data.json;
import vibe.data.serialization;
import std.base64 : Base64URLNoPadding;
import secured.hash : HashAlgorithm;
import std.format : format;
import std.datetime;
public import vibe.web.auth;

// Following is some helper functions to make sure the implementation is consistent

private ubyte[] defaultKey;

static this() {
    defaultKey = generateIDArr(32);
}

/// Gets the default key used for signing the tokens
string getDefaultKey() {
    return b64Encode(defaultKey);
}

/// Encode a string to a base64 string that is compatible
string b64Encode(string data) {
    return Base64URLNoPadding.encode(stringToBytes(data));
}

/// Encode a byte array to a base64 string that is compatible
string b64Encode(ubyte[] data) {
    return Base64URLNoPadding.encode(data);
}

/// Decode a base64 string to a series of bytes
ubyte[] b64Decode(string b64) {
    return Base64URLNoPadding.decode(b64);
}

/// Convert a string to an array of bytes
ubyte[] stringToBytes(string utf8) {
    import std.string : representation;
    return utf8.representation.dup;
}

/// Convert an array of bytes to a string
string bytesToString(ubyte[] bytes) {
    return cast(string)bytes;
}

/**
    The signature algorithm for the token
*/
enum JWTAlgorithm : string {
    HS256 = "HS256",
    HS384 = "HS384",
    HS512 = "HS512"
}

/**
    The header of a JSON web token
*/
struct JWTHeader {
    /// The algorithm for the signature
    @name("alg")
    JWTAlgorithm algorithm;

    /// Type is generally Json Web Token
    @name("typ")
    string type = "JWT";

    string toString() {
        return serializeToJsonString(this);
    }
}

/**
    A JSON Web Token
*/
struct JWTToken {
public:
    /**
        The header of a JWT Token        
    */
    JWTHeader header;

    /**
        The payload of a JWT token
    */
    Json payload;

    /**
        The saved signature of a JWT Token
    */
    string signature;

    /**
        Creates a token instance from an already completed token (used to verify tokens)
    */
    this(string jwtToken) {
        import std.array : split;

        // If the structure is invalid throw an exception        
        if (!validateJWTStructure(jwtToken)) throw new Exception("Invalid JWT structure!");

        // Split from the '.' character, then decode the segments of the token
        string[] parts = jwtToken.split('.');
        header = deserializeJson!JWTHeader(parts[0].b64Decode.bytesToString());
        payload = parseJsonString(parts[1].b64Decode.bytesToString());
        signature = parts[2];
    }

    /**
        Creates a new JWT Token
    */
    this(T)(JWTHeader header, T payload) {
        this.header = header;
        this.payload = payload;
    }

    /**
        Sign the JWT Token
    */
    void sign(ubyte[] secret) {
        signature = genSignature(header, payload, secret);
    }

    /**
        Sign the JWT Token with the randomly generated default key
    */
    void sign() {
        sign(defaultKey);
    }

    /**
        Verifies that the token is valid at current time and that it hasn't been tampered with
    */
    bool verify(ubyte[] secret) {

        // Get the current time, used in calculations
        immutable(long) currentTime = Clock.currStdTime();

        // Make sure that the expiry time actually exists.
        if (payload["exp"].type != Json.Type.undefined) {

            // Get EXP time, if not available, set to smallest possible value.
            immutable(long) expiryTime = payload["exp"].opt!long(long.min);

            // The token has expired.
            if (currentTime >= expiryTime) return false;
        }

        // Make sure that the not-before time actually exists.
        if (payload["nbf"].type != Json.Type.undefined) {
            
            // Get NBF time, if not available, set to smallest possible value.
            immutable(long) nbfTime = payload["nbf"].opt!long(long.min);

            // The token has expired.
            if (currentTime < nbfTime) return false;
        }

        // Finally check the signature
        return verifySignature(this, secret);
    }

    /**
        Verifies that the token isn't expired and hasn't been tampered with with the randomly generated default key
    */
    bool verify() {
        return verify(defaultKey);
    }
    
    /** 
        Output the final JWT token
    */
    string toString() {
        // return the fo
        return "%s.%s.%s".format(header.toString().b64Encode(), payload.toString().b64Encode(), signature);
    }
}

/**
    Validates the structure of the JWT token
*/
bool validateJWTStructure(string jwtString) {
    import std.algorithm.searching : count;
    return jwtString.count(".") == 2;
}

/**
    Generate a signature for a JWT token
*/
string genSignature(JWTHeader header, Json payload, ubyte[] secret) {
    string toSign = "%s.%s".format(header.toString().b64Encode(), payload.toString().b64Encode());

    // All the signing here does somewhat the same, just passes a different SHA algorithm in
    final switch(header.algorithm) {
        case JWTAlgorithm.HS256:
            return hmac_ex(secret, stringToBytes(toSign), HashAlgorithm.SHA2_256).b64Encode();
        case JWTAlgorithm.HS384:
            return hmac_ex(secret, stringToBytes(toSign), HashAlgorithm.SHA2_384).b64Encode();
        case JWTAlgorithm.HS512:
            return hmac_ex(secret, stringToBytes(toSign), HashAlgorithm.SHA2_512).b64Encode();
    }
}

/**
    Verify that the jwt hasn't been tampered with
*/
bool verifySignature(string token, ubyte[] secret) {
    return verifySignature(JWTToken(token), secret);
}

/**
    Verify that the jwt hasn't been tampered with
*/
bool verifySignature(JWTToken token, ubyte[] secret) {
    string toSign = "%s.%s".format(token.header.toString().b64Encode(), token.payload.toString().b64Encode());

    // All the verifications here does somewhat the same, just passes a different SHA algorithm in
    final switch(token.header.algorithm) {
        case JWTAlgorithm.HS256:
            return hmac_verify_ex(token.signature.b64Decode, secret, stringToBytes(toSign), HashAlgorithm.SHA2_256);
        case JWTAlgorithm.HS384:
            return hmac_verify_ex(token.signature.b64Decode, secret, stringToBytes(toSign), HashAlgorithm.SHA2_384);
        case JWTAlgorithm.HS512:
            return hmac_verify_ex(token.signature.b64Decode, secret, stringToBytes(toSign), HashAlgorithm.SHA2_512);
    }
}

import vibe.http.server;
import vibe.core.log : logInfo;


/**
    JWT Auth Info
*/
import backend.user;
static struct JWTAuthInfo {
    User user;
    JWTToken* token;

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

/**
    Implements JWT check
*/
template implemementJWT() {
    import vibe.web.web : noRoute;
    import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
    import vibe.core.log : logInfo;
    import backend.user : User;

    @noRoute
    @trusted
    static JWTAuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res) {
        import std.algorithm.searching : startsWith;
        immutable(string) header = req.headers.get("Authorization", null);

        // Header does not exist
        if (header is null) throw new HTTPStatusException(HTTPStatus.unauthorized, "Not logged in");

        if (!header.startsWith("Bearer ")) throw new HTTPStatusException(HTTPStatus.unauthorized, "Invalid bearer token!");

        // Verify token
        auto token = new JWTToken(header[7..$]);
        if (!token.verify()) throw new HTTPStatusException(HTTPStatus.forbidden, "Invalid token (tamper protection)");

        // Token is fine, continue on.
        return JWTAuthInfo(User.getFromJWT(token), token);
    }
}

/**
    Base class that implements JWT checks
*/
class AuthEndpoint {
    mixin implemementJWT;
}