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
module backend.category;
import db;
import vibe.data.serialization;
import backend.common;

/**
    A category compound, can contain groups and categories
*/
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
class CategoryGroup {
    /**
        Name of the group
    */
    string name;

    /**
        Children of the group
    */
    CategoryCompound[] children;    
}

/**
    A category
*/
class Category {
    /**
        ID of the category
    */
    @name("_id")
    @optional
    BsonObjectID id;

    /**
        Display name of the category
    */
    string displayName;
}

// /**

// */
// class CategoryGroup {
// @trusted:

//     static MongoCursor!CategoryGroup getList(string gameId) {
//         return DATABASE["speedrun.catgroup"].find!CategoryGroup(["gameId": gameId]);
//     }

//     /**
//         Gets ILCategory
//     */
//     static CategoryGroup get(string id) {
//         return DATABASE["speedrun.catgroup"].findOne!CategoryGroup(["_id": id]);
//     }
    
    
//     /**
//         Returns true if a category group exists.
//     */
//     static bool exists(string group) {
//         return DATABASE["speedrun.catgroup"].count(["_id": group]) > 0;
//     }

//     /**
//         ID of the category
//     */
//     @name("_id")
//     string id;

//     /**
//         ID of game this category belongs to
//     */
//     @name("gameId")
//     string gameId;

//     /**
//         Display name of category group
//     */
//     @name("displayName")
//     string displayName;
// }

// /**
//     Category for Full Game runs
// */
// class Category {
// @trusted:
//     static MongoCursor!Category getList(string gameId, string group="") {
//         return DATABASE["speedrun.categories"].find!Category(["gameId": gameId, "groupId": group]);
//     }

//     /**
//         Gets Category
//     */
//     static Category get(string id) {
//         return DATABASE["speedrun.categories"].findOne!Category(["_id": id]);
//     }

//     /**
//         Returns true if a category exists.
//     */
//     static bool exists(string cat) {
//         return DATABASE["speedrun.categories"].count(["_id": cat]) > 0;
//     }
    
//     /**
//         ID of the category
//     */
//     @name("_id")
//     string id;

//     /**
//         ID of the category group this belongs to.
//         groupId is "" if its in the root of the game
//     */
//     @name("groupId")
//     string groupId = "";

//     /**
//         ID of game this category belongs to
//     */
//     @name("gameId")
//     string gameId;

//     /**
//         Display name of category
//     */
//     @name("displayName")
//     string displayName;

//     /**
//         Description of category
//     */
//     @name("description")
//     string description;

//     /**
//         The rules of this category
//     */
//     @name("rules")
//     string rules;

//     /**
//         Wether this category is an IL category
//     */
//     @name("isIL")
//     bool individualLevel;

//     this() { }

//     this(string gameId, string displayName, bool il, string group="") {

//         // Generate a unique ID, while ensuring uniqueness
//         do { this.id = generateID(16); } while(Category.exists(this.id));

//         this.gameId = gameId;
//         this.displayName = displayName;
//         this.groupId = group;
//         this.individualLevel = il;
//         DATABASE["speedrun.categories"].insert(this);
//     }

//     void update() {
//         DATABASE["speedrun.categories"].update(["_id": id], this);
//     }

//     void remove() {
//         DATABASE["speedrun.categories"].remove(["_id": id]);
//     }
// }

// /**
//     A level is a IL-Category sub-object being the frontend for a single IL run
// */
// class Level {
// @trusted:
//     /**
//         Gets Level
//     */
//     static Level get(string id) {
//         return DATABASE["speedrun.levels"].findOne!Level(["_id": id]);
//     }
    
//     /**
//         Returns true if a level exists.
//     */
//     static bool exists(string lvl) {
//         return DATABASE["speedrun.levels"].count(["_id": lvl]) > 0;
//     }

//     /**
//         ID of the category
//     */
//     @name("_id")
//     string id;

//     /**
//         ID of game this category belongs to
//     */
//     @name("gameId")
//     string gameId;

//     /**
//         ID of game this category belongs to
//     */
//     @name("categoryId")
//     string categoryId;

//     /**
//         What placement the level has in the game
//         (used for ordering levels)
//     */
//     @name("placement")
//     int placement;

//     /**
//         Display name of category
//     */
//     string displayName;

//     this() { }

//     this(string gameId, string categoryId, string displayName) {

//         // Generate a unique ID, while ensuring uniqueness
//         do { this.id = generateID(16); } while(Level.exists(this.id));

//         this.gameId = gameId;
//         this.categoryId = categoryId;

//         // Make sure we're assigning this to an IL category

//         this.displayName = displayName;
//         DATABASE["speedrun.levels"].insert(this);
//     }

//     /**
//         Deletes this level
//     */
//     void remove() {
//         DATABASE["speedrun.levels"].remove(["_id": id]);
//     }
// }