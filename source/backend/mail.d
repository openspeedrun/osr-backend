module backend.mail;
import vibe.mail.smtp;
import vibe.core.log;

__gshared MailService EMAILER;

enum MailImportance {
    Low = "low",
    Normal = "normal",
    High = "high"
}

class MailService {
private:
    SMTPClientSettings settings;
    string from;

public:
    this(SMTPClientSettings settings, string from) {
        this.settings = settings;
        this.from = from;
    }

    void send(string to, string subject, string message, MailImportance importance = MailImportance.Normal) {
        try {
            Mail mail = new Mail;
            mail.bodyText = message;
            mail.headers.addField("To", to);
            mail.headers.addField("From", from);
            mail.headers.addField("Sender", from);
            mail.headers.addField("Subject", subject);
            mail.headers.addField("Importance", cast(string)importance);
            sendMail(settings, mail);
        } catch (Exception ex) {
            logError("MailService: %s", ex.msg);
        }
    }
}