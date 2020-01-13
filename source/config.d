/*
    Copyright © Clipsey 2019
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
module config;
import vibe.mail.smtp;
import vibe.data.sdl;
import vibe.data.serialization;
import vibe.core.log;


/**
    Loads a config file from a system config path
    On POSIX:
        /etc/osr/(file).sdl
        ./(file).sdl
    
    On Windows:
        .\(file).sdl
*/
T loadConfigSDLFile(T)(string configName, bool optional = false) {
    import std.file : exists, write;
    import std.path : buildPath;
    import sdlang.parser : parseFile;

    string withExt = (configName~".sdl");

    version(Posix) {
        // If local path version exists, use that
        if (withExt.exists) return deserializeSDLang!T(parseFile(withExt));
        
        // Get systemwide path
        string systemwide = buildPath("/etc/osr", withExt);

        // Try using the system wide version
        if (systemwide.exists) return deserializeSDLang!T(parseFile(systemwide));

        // Throw error if everything fails miserably & this config file not being optional.
        if (!optional) throw new Exception("Could not find configuration file!");

    } else version (Windows) {

        // If local path version exists, use that
        if (withExt.exists) return deserializeSDLang!T(parseFile(withExt));

        // Throw error if everything fails miserably & this config file not being optional.
        if (!optional) throw new Exception("Could not find configuration file!");
    } else {
        static assert(0, "This operating system is not supported!");
    }

    logInfo("No configuration was found, a new osrconfig.sdl file has been generated!");

    // Return default state of config, while writing a new config file
    write(withExt, serializeSDLang!T(T.init).toSDLDocument());
    return T.init;
}

/// The configuration of the server
__gshared ServerConfig CONFIG;

/**
    Server authentication options
*/
struct ServerAuthConfig {
@trusted:
    /// Wether the server allows people to sign up
    @optional
    bool allowSignups = true;

    /// Wether the server should provide OTP 2FA, this is by default enabled
    @optional
    bool enable2FA = true;

    /// Wether accounts need to be verified by email
    @optional
    bool emailVerification = true;

    @optional
    uint maxEmailLength = 72;

    @optional
    uint minUsernameLength = 3;

    @optional
    uint maxUsernameLength = 72;

    @optional
    uint minPasswordLength = 8;

    @optional
    uint maxPasswordLength = 64;

    string recaptchaSecret = "INSERT_SECRET";

    string recaptchaSiteKey = "INSERT_SITE_KEY";
}

/**
    Relevant SMTP settings
*/
struct ServerEmailSettings {
@trusted:

    /// The client username
    string username;

    /// The client password
    string password;
    
    /// The IP/DNS name of the server the SMTP server is on
    @optional
    string host = "localhost";
    
    /// The port the SMTP server is on
    @optional
    ushort port = 25;

    /// The email address to show as sender
    @optional
    string originEmail;

    /**
        Converts this instance of ServerEmailSettings to an instance of SMTPClientSettings

        == Notes ==
        TLS is *required*
        Authentication type is *login*
    */
    SMTPClientSettings toClientSettings() {
        SMTPClientSettings settings = new SMTPClientSettings;
        settings.authType = SMTPAuthType.login;
        settings.connectionType = SMTPConnectionType.tls;
        settings.host = host;
        settings.port = port;
        settings.username = username;
        settings.password = password;
        return settings;
    }

    string getAddress() {
        import std.format : format;

        // If a origin email is set, return the origin email
        if (originEmail != null && originEmail != "") return originEmail;

        // Otherwise, build an origin email out of the username and host
        return "%s@%s".format(username, host);
    }
}

/**
    Struct containing the server configuration
*/
struct ServerConfig {
@safe:
    /**
        Settings for the email server
    */
    ServerEmailSettings smtp;

    /**
        Server authentication settings
        By default all authentication is enabled
    */
    @optional
    ServerAuthConfig auth;

    /**
        The address to bind the server to
    */
    @optional
    string bindAddress = "127.0.0.1:8080";

    /**
        Connection String for the MongoDB database
    */
    @optional
    string dbConnectionString = "mongodb://127.0.0.1";

    /**
        Base address of the OSR server
    */
    @optional
    string baseAddress = "http://localhost:8080/";
}

/**
    CHANGE THESE TO CHANGE PASSWORD SECURITY

    N set to double of 2017 recommended value
*/
enum SCRYPT_N = 65_536;
enum SCRYPT_R = 8;
enum SCRYPT_P = 1;
enum SCRYPT_MAX_MEM = 1_074_790_400;
enum SCRYPT_LENGTH = 64;
enum SCRYPT_SALT_LENGTH = 32;

enum FOOTER_MSG_INSTANCE = "Powered by OpenSpeedRun! This site is not affiliated/endorsed with/by the OSR team.";