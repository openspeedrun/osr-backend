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
module backend.category;
import db;
import vibe.data.serialization;
import backend.common;

/**
    A category compound, can contain groups and categories
*/
@safe
class CategoryCompound {

    /**
        The groups in the compound
    */
    CategoryGroup[] groups;

    /**
        The categories in the compound
    */
    Category[] categories;

}

/**
    A category group, groups multiple compounds under one name
*/
@safe
class CategoryGroup {
    /**
        Name of the group
    */
    string displayName;

    /**
        Children of the group
    */
    CategoryCompound[] children;    
}

/**
    A category
*/
@safe
class Category {
    /**
        ID of the category
    */
    @name("_id")
    @optional
    string id;

    /**
        Display name of the category
    */
    string displayName;

    this() { }

    /**
        Creates a new category
    */
    this(string displayName) {
        this.id = generateID();
        this.displayName = displayName;
    }
}

/**
    A level is a IL-Category sub-object being the frontend for a single IL run
*/
class Level {
@trusted:
    /**
        Gets Level
    */
    static Level get(string id) {
        return DATABASE["speedrun.levels"].findOne!Level(["_id": id]);
    }
    
    /**
        Returns true if a level exists.
    */
    static bool exists(string lvl) {
        return DATABASE["speedrun.levels"].count(["_id": lvl]) > 0;
    }

    /**
        ID of the category
    */
    @name("_id")
    string id;

    /**
        ID of game this category belongs to
    */
    @name("gameId")
    string gameId;

    /**
        ID of game this category belongs to
    */
    @name("categoryId")
    string categoryId;

    /**
        What placement the level has in the game
        (used for ordering levels)
    */
    @name("placement")
    int placement;

    /**
        Display name of category
    */
    string displayName;

    this() { }

    this(string gameId, string categoryId, string displayName) {

        // Generate a unique ID, while ensuring uniqueness
        do { this.id = generateID(16); } while(Level.exists(this.id));

        this.gameId = gameId;
        this.categoryId = categoryId;

        // Make sure we're assigning this to an IL category

        this.displayName = displayName;
        DATABASE["speedrun.levels"].insert(this);
    }

    /**
        Deletes this level
    */
    void remove() {
        DATABASE["speedrun.levels"].remove(["_id": id]);
    }
}