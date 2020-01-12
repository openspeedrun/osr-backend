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
module api.game;
import vibe.web.rest;
import vibe.http.common;
import api.common;
import backend.user;
import backend.game;
import backend.auth.jwt;

struct GameCreationData {
    string name;
    string description;
}

@path("/games")
@requiresAuth
interface IGameEndpoint : JWTEndpoint!JWTAuthInfo {
    /**
        Get game info
    */
    @method(HTTPMethod.GET)
    @path("/:gameId")
    @noAuth
    StatusT!Game game(string _gameId);

    /**
        Search for games
    */
    @method(HTTPMethod.GET)
    @path("/search/:page")
    @queryParam("pgCount", "pgCount")
    @queryParam("showPending", "showPending")
    @queryParam("query", "query")
    @noAuth
    StatusT!(Game[]) search(string query, int _page = 0, int pgCount = 20, bool showPending = false);

    /**
        Creates a new game
    */
    @method(HTTPMethod.POST)
    @path("/:gameId")
    @bodyParam("data")
    @auth(Role.User)
    Status createGame(JWTAuthInfo token, string _gameId, GameCreationData data);

    /**
        Promotes a user to moderator of the game
    */
    @method(HTTPMethod.POST)
    @path("/:gameId/promote/:userId/:rank")
    @auth(Role.User)
    Status setRank(JWTAuthInfo token, string _gameId, string _userId, int _rank);

    /**
        === Moderator+ ===
        
        Accepts the pending game, if any.
    */
    @method(HTTPMethod.POST)
    @path("/accept/:gameId")
    @auth(Role.Mod)
    Status acceptGame(JWTAuthInfo token, string _gameId);

    /**
        === Moderator+ ===
        
        Denies the pending game, if any.

        This will delete the game from the server.
    */
    @method(HTTPMethod.POST)
    @path("/deny/:gameId")
    @auth(Role.Mod)
    Status denyGame(JWTAuthInfo token, string _gameId);
}

class GameEndpoint : IGameEndpoint {
public:

    StatusT!Game game(string _gameId) {
        Game game = Game.get(_gameId);
        return StatusT!Game(game !is null ? StatusCode.StatusOK : StatusCode.StatusInvalid, game);
    }

    StatusT!(Game[]) search(string query, int _page = 0, int pgCount = 20, bool showPending = false) {
        Game[] games;
        foreach(game; Game.search(query, _page, pgCount).result) {
            if (!showPending && !game.approved) continue;
            games ~= game;
        }
        return StatusT!(Game[])(StatusCode.StatusOK, games);
    }

    Status createGame(JWTAuthInfo token, string _gameId, GameCreationData data) {

        // Make sue that the user is valid
        if (!User.getValidFromJWT(token.token)) return Status(StatusCode.StatusInvalid);
        User user = User.getFromJWT(token.token);


        // Make sure Game DOES NOT exists.
        if (Game.get(_gameId) !is null) return Status(StatusCode.StatusInvalid);


        Game game = new Game(_gameId, data.name, data.description, user.username);
        return game !is null ? Status(StatusCode.StatusOK) : Status(StatusCode.StatusInvalid);
    }

    @auth(Role.User)
    Status setRank(JWTAuthInfo token, string _gameId, string _userId, int _rank) {

        // Make sue that the user is valid
        if (!User.getValidFromJWT(token.token)) return Status(StatusCode.StatusInvalid);

        // Make sure the game exists
        if (Game.get(_gameId) is null) return Status(StatusCode.StatusInvalid);

        // TODO: finish this
        return Status(StatusCode.StatusInternalErr);
    }

    Status acceptGame(JWTAuthInfo token, string _gameId) {
        
        // Make sure the game exists
        Game game = Game.get(_gameId);
        if (game is null) return Status(StatusCode.StatusInvalid);

        // Make sure the user has the permissions to accept the CSS
        if (!User.getValidFromJWT(token.token)) return Status(StatusCode.StatusInvalid);
        User user = User.getFromJWT(token.token);

        game.accept();
        return Status(StatusCode.StatusOK);
    }

    @auth(Role.Mod)
    Status denyGame(JWTAuthInfo token, string _gameId) {
        
        // Make sure the game exists
        Game game = Game.get(_gameId);
        if (game is null) return Status(StatusCode.StatusInvalid);

        game.deleteGame();
        return Status(StatusCode.StatusOK);
    }
}