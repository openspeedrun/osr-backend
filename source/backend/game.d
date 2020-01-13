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
module backend.game;
import db;
import backend.user;
import backend.category;
import backend.common;
import vibe.data.serialization;
import vibe.data.bson;
import vibe.db.mongo.collection : QueryFlags;
import vibe.db.mongo.cursor : MongoCursor;
import std.algorithm.searching : canFind;

/**
    Info about the game
*/
struct GameInfo {
    /**
        Link to image of game's box art
    */
    string boxart;

    /**
        Short description of the game

        128 characters max.
    */
    @limit(128)
    string shortDescription;

    /**
        The year of release
    */
    ushort releaseYear;

    /**
        Where to buy the game
    */
    string[] buyLinks;

    /**
        Official game community pages (discord, etc.)
    */
    string[] communityPages;
}

@safe
class Game {
private:

public:
    /**
        Gets a game via id

        Returns null if game doesn't exist with specified id.
    */
    static Game get(string gameId) {
        return DATABASE["speedrun.games"].findOne!Game(["_id": gameId]);
    }
    
    /**
        Search for games, returns a cursor looking at the games.
    */
    static SearchResult!Game search(string queryString, int page = 0, int countPerPage = 20, bool showUnapproved = false) {
        if (queryString == "" || queryString is null) return list(page, countPerPage);

        auto inquery = bson([
                "$and": bson([
                    bson(["$or": 
                        bson([
                            bson(["_id": bson(["$regex": bson(queryString)])]),
                            bson(["name": bson(["$regex": bson(queryString)])]),
                            bson(["description": bson(["$regex": bson(queryString)])
                        ])
                    ])]),
                    bson(["approved": bson(showUnapproved)])
                ])
            ]);

        return SearchResult!Game(
            DATABASE["speedrun.games"].count(inquery), 
            DATABASE["speedrun.games"].find!Game(
                inquery, 
                null, 
                QueryFlags.None, 
                page*countPerPage, 
                countPerPage
            )
        );
    }

    static SearchResult!Game list(int page = 0, int countPerPage = 20, bool showUnapproved = false) {
        import std.stdio : writeln;
        Bson inquery = (!showUnapproved) ? 
            bson(["approved": bson(true)]) : 
            Bson.emptyObject;

        return SearchResult!Game(
            DATABASE["speedrun.games"].count(inquery),
            DATABASE["speedrun.games"].find!Game(
                inquery, 
                null, 
                QueryFlags.None, 
                page*countPerPage, 
                countPerPage
            )
        );    
    }

    /**
        ID of the game
    */
    @name("_id")
    string id;

    /**
        Wether this game has been approved
    */
    bool approved;

    /**
        Wether ingame time should be displayed.
    */
    bool hasIngameTimer;

    /**
        Name of the game
    */
    @name("name")
    string gameName;

    /**
        Description of game
    */
    string description;

    /**
        The owner of the game on-site

        owner = admin but can't be demoted
    */
    string owner;

    /**
        List of admins
    */
    string[] admins;

    /**
        List of mods
    */
    string[] mods;

    /**
        Category Compound of full game runs
    */
    CategoryCompound fullGame;

    /**
        Category compound of individual level runs
    */
    CategoryCompound indivdualLevel;

    /**
        The ID of the game series this game belongs to
    */
    @optional
    string gameSeries;

    /**
        Where to buy the game
    */
    @optional
    string storePage;

    this() {}

    this(string id, string name, string description, string adminId) {
        this.id = id;
        this.gameName = name;
        this.description = description;
        this.approved = false;
        this.owner = adminId;
        DATABASE["speedrun.games"].insert(this);
    }

    /**
        Returns true if the user with the specified id is a server-wide admin

        == NOTE ==
        Such admins needs to be vetted thoroughly as they have access to modify the state of the entire server.
    */
    bool isServerAdmin(string userId) {
        User user = User.get(userId);
        return user !is null && user.power >= Powers.Admin;
    }

    /**
        Returns true if the user with specified id is the owner of the server
    */
    bool isOwner(string userId) {
        return owner == userId || isServerAdmin(userId);
    }

    /**
        Returns true if the user with specified id is an admin of the server
    */
    bool isAdmin(string userId) {
        return admins.canFind(userId) || isOwner(userId);
    }

    /**
        Returns true if the user with specified id is an moderator of the server
    */
    bool isMod(string userId) {
        return mods.canFind(userId) || isAdmin(userId);
    }

    /**
        Accept game
    */
    void accept() {
        approved = true;
        update();
    }

    /**
        Revoke a game's accepted status
    */
    void revoke() {
        approved = false;
        update();
    }

    /**
        Update the game instance in the DB
    */
    void update() {
        DATABASE["speedrun.games"].update(["_id": id], this);
    }

    /**
        Delete game
    */
    void deleteGame() {
        DATABASE["speedrun.games"].remove(["_id": id]);
    }
}