module backend.registrations;
import vibe.data.serialization;
import backend.user;
import db;
import backend.common;
import backend.mail;
import std.format;
import config;

class Registration {

    /**
        The registration key
    */
    @name("_id")
    string key;

    /**
        The user name
    */
    string userName;

    /**
        Queues user for registration
    */
    static void queueUser(string userId) {
        auto reg = new Registration();
        reg.key = generateID(64);
        reg.userName = userId;

        // Get user attached to this registration
        User user = User.get(reg.userName);

        // User does not exist??
        if (user is null) return;

        DATABASE["speedrun.reg"].insert(reg);

        // Send email to user with verification link
        EMAILER.send(
            user.email, 
            "OpenSpeedRun Account Verification", 
            import("verify_email.html").format(CONFIG.baseAddress, reg.userName, reg.key), 
            MailImportance.High);
    }

    static bool verifyUser(string key) {
        Registration reg = DATABASE["speedrun.reg"].findOne!Registration(["_id": key]);
        
        // No registration found
        if (reg is null) return false;

        User user = User.get(reg.userName);

        // User does not exist??
        // In that case the registration should be removed.
        if (user is null) {
            reg.remove();
            return false;
        }

        // Verify user and remove the registration index
        user.verified = true;
        user.update();
        reg.remove();
        return true;
    }

    void remove() {
        DATABASE["speedrun.reg"].remove(["_id": key]);
    }

}