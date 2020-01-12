*/
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
module api.user;
import api.common;
import backend.user;
import backend.common;
import config;


/**
    User endpoint for user settings
*/
@path("/users")
@requiresAuth
interface IUserEndpoint : JWTEndpoint!JWTAuthInfo {

    /**
        Gets user info
    */
    @path("/:userId")
    @method(HTTPMethod.GET)
    @noAuth
    FEUser user(string _userId);

    /**
        Search for games
    */
    @method(HTTPMethod.GET)
    @path("/search/:page")
    @queryParam("pgCount", "pgCount")
    @queryParam("query", "query")
    @noAuth
    FEUser[] search(string query, int _page = 0, int pgCount = 20);

    /**
        Endpoint changes user info
    */
    @path("/update")
    @method(HTTPMethod.GET)
    @auth(Role.User)
    string update(JWTAuthInfo token, User data);

    /**
        === Moderator+ ===


    */
    @path("/ban/:userId")
    @method(HTTPMethod.POST)
    @queryParam("community", "c")
    @auth(Role.Mod)
    string ban(JWTAuthInfo token, string _userId, bool community = true);

    /**
        === Moderator+ ===
    */
    @path("/pardon/:userId")
    @method(HTTPMethod.POST)
    @auth(Role.Mod)
    string pardon(JWTAuthInfo token, string _userId);

    /**
        Removes user from database with token.

        DO NOTE:
        Verify with password!
    */
    @path("/rmuser")
    @auth(Role.User)
    string rmuser(JWTAuthInfo token, string password);

}

@requiresAuth
class UserEndpoint : IUserEndpoint {
public:

    FEUser user(string userId) {
        User user = User.get(userId);
        if (user is null) throw new HTTPStatusException(404, "user not found!");
        return user.getInfo();
    }

    FEUser[] search(string query, int _page = 0, int pgCount = 20) {
        auto search = User.search(query, _page, pgCount);
        FEUser[] outData = new FEUser[search.resultsCount];
        size_t i = 0;
        foreach(User user; search.result) {
            outData[i++] = user.getInfo();
        }
        return outData;
    }

    string update(JWTAuthInfo token, User data) {
        return StatusCode.StatusOK;
    }

    string ban(JWTAuthInfo token, string _userId, bool community = true) {

        // Make sure the user has the permissions neccesary
        if (!User.getValidFromJWT(token.token)) throw new HTTPStatusException(HTTPStatus.unauthorized);
        User user = User.getFromJWT(token.token);

        User toBan = User.get(_userId);
        if (!user.canPerformActionOn(toBan)) throw new HTTPStatusException(HTTPStatus.unauthorized);

        if (!toBan.ban(community)) throw new HTTPStatusException(HTTPStatus.internalServerError);

        // Ban the user
        return StatusCode.StatusOK;
    }

    string pardon(JWTAuthInfo token, string _userId) {
        // Make sure the user has the permissions neccesary
        if (!User.getValidFromJWT(token.token)) throw new HTTPStatusException(HTTPStatus.unauthorized);
        User user = User.getFromJWT(token.token);
        if (user.power < Powers.Mod) throw new HTTPStatusException(HTTPStatus.unauthorized);

        // Get the user and try to perform the action
        User toPardon = User.get(_userId);
        if (!user.canPerformActionOn(toPardon)) throw new HTTPStatusException(HTTPStatus.unauthorized);
        if (!toPardon.unban()) throw new HTTPStatusException(HTTPStatus.internalServerError);

        return StatusCode.StatusOK;
    }

    @auth(Role.User)
    string rmuser(JWTAuthInfo token, string password) {
        
        // Make sure the user has the permissions neccesary
        if (!User.getValidFromJWT(token.token)) throw new HTTPStatusException(HTTPStatus.unauthorized);
        User user = User.getFromJWT(token.token);
        if (!user.auth.verify(password)) throw new HTTPStatusException(HTTPStatus.unauthorized);
        user.deleteUser();
        return StatusCode.StatusOK;
    }
}
