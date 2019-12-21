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
module backend.common;
import std.regex : split, regex;
import std.conv : to;

import db;
public import vibe.data.serialization;
public import vibe.db.mongo.collection : MongoCollection;
public import vibe.db.mongo.cursor : MongoCursor;

/**
    Implements some mongodb utilities
    T = Type of class
    I = _id variable/field
    collection = The MongoDB collection
*/
template MongoUtils(T, I, string collection) {

    /**
        Returns the collection associated with this object
    */
    MongoCollection collection() {
        return DATABASE[DB_COLLECTION];
    }

    /**
        The database collection for the implementation
    */
    enum DB_COLLECTION = collection;

    /**
        Checks wether an ID was taken
    */
    static bool hasId(string id) {
        return DATABASE[DB_COLLECTION].count(["_id": id]) > 0;
    }

    /**
        Finds an instance of this class and gets it from the database
    */
    static T get(string id) {
        return DATABASE[DB_COLLECTION].findOne!T(["_id": id]);
    }

    /**
        Create an entry in the database with the contents of this class.
    */
    void save() {
        if (hasId(I)) {
            update();
        } else {
            insert();
        }
    }

    void update() {
        DATABASE[DB_COLLECTION].update(["_id": I], cast(T)this);
    }

    void insert() {
        DATABASE[DB_COLLECTION].insert(cast(T)this);
    }

    /**
        Remove this instance.
    */
    void remove() {
        DATABASE[DB_COLLECTION].remove(["_id": I]);
    }
}

class Attachment {
@trusted:
    /**
        The type of object this is attached to
    */
    ubyte type;

    /**
        The ID of the object this is attached to.
    */
    string id;

    this(ubyte type, string id) {
        this.type = type;
        this.id = id;
    }

    this() { }
}

class SRTimeStamp {
@trusted:
    /++
        Creates a new timestamp from an input string
    +/
    static SRTimeStamp fromString(string input) {
        string[] timeSlices = input.split(regex(`:|\.|(h )|(m )|(s )|(ms)`));
        if (timeSlices.length != 4) throw new InvalidFmtException("timestamp", "HH:MM:SS.ms");
        return new SRTimeStamp(timeSlices[0].to!int, timeSlices[1].to!int, timeSlices[2].to!int, timeSlices[3].to!int);
    }

    /++
        Hours it took to complete the speedrun
    +/
    int hours;

    /++
        Minutes it took to complete the speedrun
    +/
    int minutes;

    /++
        Seconds it took to complete the speedrun
    +/
    int seconds;

    /++
        Miliseconds it took to complete the speedrun
    +/
    int msecs;

    this(int hours, int minutes, int seconds, int msecs) {
        this.hours = hours;
        this.minutes = minutes;
        this.seconds = seconds;
        this.msecs = msecs;
    }

    /++
        Returns a self-parsable time format
    +/
    override string toString() {
        import std.format : format;
        return "%d:%d:%d.%d".format(hours, minutes, seconds, msecs);
    }

    /++
        Returns a human readable time format
    +/
    string toHumanReadable() {
        import std.format : format;
        return "%dh %dm %ds %dms".format(hours, minutes, seconds, msecs);
    }
}

/++
    The result of a search
+/
struct SearchResult(T) {
    import vibe.db.mongo.cursor : MongoCursor;
    /++
        How many results were found in total on the server
    +/
    ulong resultsCount;

    /++
        The mongo cursor over the results
    +/
    MongoCursor!T result;
}

/++
    Exception that expresses that an element for an Action is already been used.
+/
class TakenException : Exception {
    this(string takenElm) {
        import std.format : format;
        super("%s is already taken!".format(takenElm));
    }
}

/++
    Exception that express that an element had the wrong format for the Action.
+/
class InvalidFmtException : Exception {
    this(string elm, string expected) {
        import std.format : format;
        super("invalid format for %s! expected: %s".format(elm, expected));
    }
}

enum ExpectedIDFmt = "a-z, A-Z, 0-9, '_', '-', '.'";

/++
    Formats ids
    IDs can contain:
     * Alpha Numeric Characters
     * _
     * -
     * .

    Spaces will automatically be converted to _
    Other characters will be discarded
+/
string formatId(string id) {
    import std.uni : isAlphaNum;
    string outId;
    foreach(c; id) {
        switch(c) {
            case ' ':
                outId ~= "_";
                break;
            case '_':
            case '-':
            case '.':
                outId ~= c;
                break;
            default:
                if (isAlphaNum(c)) {
                    outId ~= c;
                }
                break;
        }
    }
    return outId;
}

string generateID(int length = 16) {
    import std.base64 : Base64URLNoPadding;
    import secured.random;
    return Base64URLNoPadding.encode(random(length));
}

ubyte[] generateIDArr(int length = 16) {
    import std.base64 : Base64URLNoPadding;
    import secured.random;
    return random(length);
}