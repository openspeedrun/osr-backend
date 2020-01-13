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
module backend.run;
import db;
import vibe.data.serialization;
import backend.common;
import backend;
import std.datetime;

/**
    The type of a run
*/
enum RunType : ubyte {
    /**
        An Full-Game Run
    */
    FG,

    /**
        An Individual-Level Run
    */
    IL
}


/**
    The runner of a run

    This is a container structure to contain the runner and the setup they used.
*/
struct RunRunner {
    string id;
    SetupData* setup;

    /**
        Ensures that no unneded data is snuck in to the run
    */
    void ensureComplianceRun() {
        timeStamp = null;
        timeStampIG = null;
    }

    /**
        Ensures that needed data is provided with run
    */
    void ensureComplianceRace() {
        if (timeStamp is null) throw new Exception("No timestamp was provided");
    }

    /**
        How long the run took to complete in real-time

        This is for races, will not be present in normal runs
    */
    @optional
    SRTimeStamp timeStamp;
    
    /**
        How long the run took to complete in In-Game time

        This is for races, will not be present in normal runs
    */
    @optional
    SRTimeStamp timeStampIG;
}

struct RunCreationData {
    /**
        The ID of the runner who posted the run
    */
    string posterId;

    /**
        The people running the game
    */
    RunRunner[] runners;

    /**
        Category this is attached to
    */
    string attachment;

    /**
        How long the run took to complete in real-time
    */
    SRTimeStamp timeStamp;
    
    /**
        How long the run took to complete in In-Game time

        Leave blank/null for no Ingame timer
    */
    SRTimeStamp timeStampIG;

    /**
        Link to video proof of completion
    */
    string proof;

    /**
        User-set description
    */
    string description;
}

/**
    A run
*/
class Run {
@trusted:
    /**
        Returns run instance if exists.
    */
    static Run get(string runId) {
        return DATABASE["speedrun.runs"].findOne!Run(["_id": runId]);
    }

    /**
        Returns the amount of runs attributed to a user
    */
    static ulong getRunCountForUser(string userId) {
        return DATABASE["speedrun.runs"].count(["userId": userId]);
    }
    
    /**
        Checks wether an ID was taken
    */
    static bool has(string id) {
        return DATABASE["speedrun.runs"].count(["_id": id]) > 0;
    }

    /**
        ID of the run
    */
    @name("_id")
    string id;

    /**
        The ID of the runner that posted this.

        The runner this refers to is the only (non mod/admin) person who may update the run data.
    */
    string userId;

    /**
        ID of the runner
    */
    @name("runners")
    RunRunner[] runners;

    /**
        The object this run is attached to.
    */
    string parentId;

    /**
        Date and time this run was posted
    */
    DateTime postDate;

    /**
        How long the run took to complete in real-time
    */
    SRTimeStamp timeStamp;
    
    /**
        How long the run took to complete in In-Game time
    */
    SRTimeStamp timeStampIG;

    /**
        Link to video proof of completion
    */
    string proof;

    /**
        User-set description
    */
    string description;

    /**
        Wether the run has been invalidated.
    */
    bool invalidated;

    /**
        Wether the run has been verified by a game moderator
    */
    bool verified = false;

    /// For deserialization
    this() { }

    /**
        Create a new Full-Game Run
    */
    static Run newFG(RunCreationData rundata) {
        return new Run(rundata, true);
    }

    /**
        Create a new Full-Game Run
    */
    static Run newIG(RunCreationData rundata) {
        return new Run(rundata, false);
    }

    this(RunCreationData rundata, bool fg) {

        if (rundata.proof.length == 0) throw new Exception("Runs without proof are not allowed.");

        // Generate a unique ID, while ensuring uniqueness
        do { this.id = generateID(16); } while(Run.has(this.id));

        // TODO: Find a runner attached to a user, if none found create one
        
        this.posterId = rundata.posterId;
        this.attachedTo = new Attachment(fg ? RunType.FG : RunType.IL, rundata.attachment);
        this.runners = rundata.runners;
        this.postDate = cast(DateTime)Clock.currTime(UTC());
        this.timeStamp = rundata.timeStamp;
        this.timeStampIG = rundata.timeStampIG;
        this.proof = rundata.proof;
        this.description = rundata.description;

        // Sanity checks and cleanup

        if (!User.exists(this.posterId)) throw new Exception("Tried to post from nonexistant account!");
        
        // Verify that game category makes sense
        if (fg) {

            // Check if category exists
            if (!Category.exists(this.attachedTo.id)) 
                throw new Exception("Category does not exist!");

        } else {

            // Check if level exists
            if (!Level.exists(this.attachedTo.id)) 
                throw new Exception("Level does not exist!");
        }
        
        // Runs without proof might as well just be lies, enforce run proof.
        if (proof is null) throw new Exception("Cannot submit run without proof!");

        // Ensure compliance for a run
        foreach(runner; this.runners) {
            runner.ensureComplianceRun();
        }

        // Finally insert the run
        DATABASE["speedrun.runs"].insert(this);
    }

    /**
        Accept a run
    */
    void accept() {
        verified = true;
        update();
    }

    /**
        Revoke a run
    */
    void revoke() {
        verified = false;
        update();
    }

    /**
        Mark a run as invalidated
    */
    void invalidate() {
        invalidated = true;
        update();
    }

    /**
        Mark a run as validated (default)
    */
    void validate() {
        invalidated = false;
        update();
    }

    /**
        Deny a run
    */
    void deny() {
        deleteRun();
    }

    /**
        Move game from one category to an other

        This function sanity checks moves, so no games can be moved from one game to another.
    */
    void move(string to) {

        // Run sanity checks first
        if (attachedTo.type == RunType.FG) {

            if (!Category.exists(to))
                throw new Exception("Category does not exist!");

            Category oldCategory = Category.get(attachedTo.id);
            Category newCategory = Category.get(to);

            // Make sure that the user doesn't try to move the run across games
            if (oldCategory.gameId != newCategory.gameId) 
                throw new Exception("Cannot move run across games!");

        } else {

            if (!Level.exists(to))
                throw new Exception("Level does not exist!");

            Level oldLevel = Level.get(attachedTo.id);
            Level newLevel = Level.get(to);

            // Make sure that the user doesn't try to move the run across games
            if (oldLevel.gameId != newLevel.gameId) 
                throw new Exception("Cannot move run across games!");

        }

        // Update the attachment.
        attachedTo.id = to;
        update();
    }

    /**
        Update the data in the database
    */
    void update() {
        return DATABASE["speedrun.runs"].update(["_id": id], this);
    }

    /**
        Delete game
    */
    void deleteRun() {
        DATABASE["speedrun.runs"].remove(["_id": id]);
        destroy(this);
    }
}