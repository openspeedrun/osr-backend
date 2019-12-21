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
module db;
import vibe.db.mongo.client;
public import vibe.db.mongo.database;
import vibe.db.mongo.mongo;
import std.traits;
import config;

__gshared Database DATABASE;

/++
    The size limit of a string
+/
struct limit {
    /// The limit value
    int size;
}

/**
    verifies that the limit of a string value is acceptable
*/
bool verifyLimit(alias item)(string itemStr) {
    static assert(hasUDA!(item, limit), "No limit UDA set!");
    limit lmt = getUDAs!(item, limit)[0];
    return itemStr.length < lmt.size;
}

class Database {
private:
    MongoClient client;

public:
    MongoCollection opIndex(string index) {
        return client.getCollection(index);
    }

    this(string connString) {
        this.client = connectMongoDB(connString);
    }
}

shared static this() {
    DATABASE = new Database(CONFIG.dbConnectionString);
}