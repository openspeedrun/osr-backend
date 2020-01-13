module backend.meta;
import vibe.data.serialization;

/**
    Data about the hardware, etc. used to play the game
*/
struct SetupData {
@trusted:
    /**
        The platform the game runs on

        Example:
            platform=Playstation 4
    */
    string platform;

    /**
        The version of the platform the game runs on

        Example:
            platform=Windows
            platformVersion=10
    */
    string platformVersion;

    /**
        The version of the game

        Example:
            version=2.56.1-beta
    */
    @name("version")
    string version_;

    /**
        The region of the game

        Example:
            region=JP
    */
    string region;

    /**
        Wether the platform the game is running on was emulated
    */
    bool emulated;
}