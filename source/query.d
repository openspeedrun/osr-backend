module query;
import vibe.data.bson;

Bson bson(T)(T item) {
    return Bson(item);
}