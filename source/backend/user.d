/+
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
+/
module backend.user;
import vibe.data.serialization;
import vibe.data.bson;
import std.algorithm;
import std.base64;
import db;
import crypt;
import std.range;
import std.algorithm;
import backend.common;
import backend.registrations;
import config;
import backend.auth.jwt;
import vibe.db.mongo.collection : QueryFlags;
import vibe.db.mongo.cursor : MongoCursor;

/++
    User authentication info
+/
struct UserAuth {
public:
    /++
        Salt of password
    +/
    string salt;

    /++
        Hash of password
    +/
    string hash;

    /++
        Automatically generated secret for bots
    +/
    @name("secret")
    string botSecret;

    /++
        Create new userauth instance from password

        Gets hashed with scrypt.
    +/
    this(string password) {
        auto hashcomb = hashPassword(password);
        hash = Base64.encode(hashcomb.hash);
        salt = Base64.encode(hashcomb.salt);
        botSecret = generateID(32);
    }

    /++
        Verify that the password is correct
    +/
    bool verify(string password) {
        return verifyPassword(password, Base64.decode(this.hash), Base64.decode(this.salt));
    }
}

/++
    The power level of a user
+/
enum Powers : ushort {
    /**
        Has full control over server and can't be demoted
    */
    WebMaster = 1000u,
    
    /**
        Has full control over server.
    */
    Admin =   100u,

    /**
        Moderator can kick/ban users and approve/deny css, but cannot change any server settings.
    */
    Mod =       10u,

    /**
        Normal user, has normal user powers. 
    */
    User =       1u,
    
    /**
        User is social banned

        This means that the user cannot post any comments, nor post in the forum or any other social place on the site.

        The user can still upload runs.
    */
    Banned =      0u
}

/++
    User set pronouns
+/
struct Pronouns {
    /++
        Subject part of pronoun
        eg. they
    +/
    string subject = "they";

    /++
        Object part of pronoun
        eg. them
    +/
    string object = "them";

    /++
        Posessive part of pronoun
        eg. their
    +/
    string possesive = "their";
}

/// Default pronouns for he/him
Pronouns heHimPronouns() {
    return Pronouns("he", "him", "his");
}

/// Default pronouns for she/her
Pronouns sheHerPronouns() {
    return Pronouns("she", "her", "hers");
}

/// Default pronouns for they/them
Pronouns theyThemPronouns() {
    return Pronouns("they", "them", "their");
}

struct Social {
    /**
        Name of social site
    */
    string name;

    /**
        Link to social site
    */
    string link;
}

/++
    A user
+/
class User {
@trusted public:

    static User register(string username, string email, string password) {
        if (nameTaken(username)) throw new TakenException("User name");
        if (emailTaken(email)) throw new TakenException("Email");
        
        string properUsername = formatId(username);
        if (properUsername.length == 0) throw new InvalidFmtException("username", ExpectedIDFmt);

        // Setup user
        User userToAdd = new User(properUsername, email, UserAuth(password));

        // If email verification is turned off, mark the user as verified already
        // NOTE: Maybe this shouldn't be done in the future and instead there should be general checks for this feature where needed
        if (!CONFIG.auth.emailVerification) userToAdd.verified = true;
        

        DATABASE["speedrun.users"].insert(userToAdd);

        // If email verification is turned on, queue the user for email verification
        if (CONFIG.auth.emailVerification) Registration.queueUser(username);
        
        return User.get(username);
    }

    /++
        Returns true if a user exists.
    +/
    static bool exists(string username) {
        return DATABASE["speedrun.users"].count(["_id": username]) > 0;
    }

    /++
        Gets user from database via either username or email

        returns null if no user was found
    +/
    static User get(string username) {
        return DATABASE["speedrun.users"].findOne!User([
            "$or": [
                ["_id": username], 
                ["email": username]
            ]
        ]);
    }


    /++
        Search for games, returns a cursor looking at the games.
    +/
    static SearchResult!User search(string queryString, int page = 0, int countPerPage = 20) {
        if (queryString == "" || queryString is null) return list(page, countPerPage);

        import query : bson;

        auto inquery = bson([
            "$and": bson([
                bson(["power": bson(["$gt": bson(0)])]),
                bson(["verified": bson(true)]),
                bson(["$or": 
                    bson([
                        bson(["_id": bson(["$regex": bson(queryString)])]),
                        bson(["name": bson(["$regex": bson(queryString)])]),
                        bson(["display_name": bson(["$regex": bson(queryString)])])
                    ])
                ])
            ])
        ]);

        return SearchResult!User(
            DATABASE["speedrun.users"].count(inquery), 
            DATABASE["speedrun.users"].find!User(
                inquery, 
                null, 
                QueryFlags.None, 
                page*countPerPage, 
                countPerPage
            )
        );
    }

    static SearchResult!User list(int page = 0, int countPerPage = 20) {
        import query : bson;
        import std.stdio : writeln;
        Bson inquery = bson([
            "$and": bson([
                bson(["power": bson(["$gt": bson(0)])]),
                bson(["verified": bson(true)])
            ])
        ]);

        return SearchResult!User(
            DATABASE["speedrun.users"].count(inquery),
            DATABASE["speedrun.users"].find!User(
                inquery, 
                null, 
                QueryFlags.None, 
                page*countPerPage, 
                countPerPage
            )
        );    
    }

    static User getFromSecret(string secret) {
        return DATABASE["speedrun.users"].findOne!User([
            "$or": [
                ["auth.secret": secret]
            ]
        ]);
    }

    static User getFromJWT(Token token) {
        // Verify that the token exists.
        if (token is null) return null;

        // Try to fetch username
        string username = token.payload["username"].opt!string(null);
        if (username is null) return null;

        // We got it, return user from db with that name
        return get(username);
    }

    /++
        Gets wether the user is valid on the site

        Validity:
        * Is a user
        * Has verified their email
    +/
    static bool getValid(string username) {
        User user = get(username);
        if (user is null) return false;
        return user.verified;
    }

    /++
        Gets wether the user is valid on the site from a JWT token

        Validity:
        * Is a user
        * Has verified their email
    +/
    static bool getValidFromJWT(Token token) {
        import std.stdio : writeln;
        if (token is null) return false;

        string username = token.payload["username"].opt!string(null);
        if (username is null) return false;
        return getValid(username);
    }

    /++
        Returns true if there's a user with specified username
    +/
    static bool nameTaken(string username) {
        return DATABASE["speedrun.users"].count(["_id": username]) > 0;
    }

    /++
        Returns true if there's a user with specified username
    +/
    static bool emailTaken(string email) {
        return DATABASE["speedrun.users"].count(["email": email]) > 0;
    }

    /++
        User's username (used during login)
    +/
    @name("_id")
    string username;

    /++
        User's email (used during registration and to send notifications, etc.)
    +/
    @name("email")
    string email;

    /++
        User's display name
    +/
    @name("display_name")
    string displayName;

    /++
        Link to profile picture (in CDN)

        By default "neumann.png"
    +/
    @name("profile_picture")
    @optional
    string profilePicture = "/static/app/assets/neumann.png";

    /++
        Wether the user has verified their email
    +/
    @name("verified")
    bool verified;

    /++
        The power level of a user

        THIS SHOULD ONLY BE CHANGED BY SITE ADMINS
    +/
    @name("power")
    @optional
    Powers power = Powers.User;

    /++
        User's authentication info
    +/
    @name("auth")
    UserAuth auth;

    /++
        The user's pronouns

        If not set, pronouns will default to they/them
    +/
    @name("pronouns")
    @optional
    Pronouns pronouns;

    /++
        Wether to display pronouns on a user's account, by default off.
    +/
    @name("display_pronouns")
    @optional
    bool displayPronouns = false;

    /++
        country code for the country of origin
    +/
    @name("country")
    @optional
    string country;

    /++
        Account flavourtext
    +/
    @name("flavour_text")
    @optional
    string flavourText;

    /**
        Social places
    */
    @name("socials")
    @optional
    Social[] socials;

    /++
        For serialized instances
    +/
    this() { }

    /++
        User on account creation
    +/
    this(string username, string email, UserAuth auth) {
        this.username = username;
        this.email = email;
        this.displayName = username;
        this.verified = false;
        this.power = Powers.User;
        this.auth = auth;
    }

    /++
        Delete the user from the database
    +/
    void deleteUser() {
        // Delete user and runner attached
        DATABASE["speedrun.users"].remove(["_id": username]);
        DATABASE["speedrun.runners"].remove(["_id": username]);
        destroy(this);
    }

    /++
        Returns true if social actions are permitted.

        Social actions are NOT permitted if the user has been social-banned.
    +/
    bool socialPermitted() {
        return power > Powers.Banned;
    }

    /++
        Returns true if an administrative action can be performed on the specified user
    +/
    bool canPerformActionOn(User other) {
        return power > other.power;
    }

    /++
        Bans a user.

        Set community to true for a community ban.
        Otherwise a total ban will be done.

        Returns true if successful, otherwise returns false.
    +/
    bool ban(bool community) {
        if (!exists(username)) return false;

        if (community) {
            power = Powers.Banned;
            update();
            return true;
        }
        this.deleteUser();
        return true;
    }

    /++
        Unbans a user

        Unban only works on community bans!

        Returns true if successful, otherwise returns false.
    +/
    bool unban() {
        if (!exists(username)) return false;
        User user = User.get(username);
        user.power = Powers.User;
        return true;
    }

    /++
        Applies changes to database.
    +/
    void update() {
        DATABASE["speedrun.users"].update(["_id": username], this);
    }

    FEUser getInfo() {
        return FEUser(username, displayName, profilePicture, verified, pronouns, displayPronouns, power);
    }
}

/++
    Frontend representation of a user.
+/
struct FEUser {
    /++
        User's username (used during login)
    +/
    @name("id")
    string username;

    /++
        User's display name
    +/
    @name("display_name")
    string displayName;

    /++
        User's profile picture
    +/
    @name("profile_picture")
    string profilePicture;

    /++
        Wether the user has verified their email
    +/
    @name("verified")
    bool verified;

    /++
        The user's pronouns

        If not set, pronouns will default to they/them
    +/
    @name("pronouns")
    Pronouns pronouns;

    /++
        Wether the user has pronouns enabled
    +/
    @name("pronouns_enabled")
    bool pronounsEnabled;

    /++
        The user's power level
    +/
    @name("powers")
    Powers powers;
}
