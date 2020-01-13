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
import std.stdio;
import vibe.d;
import api;
import config;
import backend.mail;

void main()
{
    URLRouter router = new URLRouter;

    logInfo("Loading configuration...");
    CONFIG = loadConfigSDLFile!ServerConfig("osrconfig", true);

    logInfo("Setting up email service...");
    EMAILER = new MailService(CONFIG.smtp.toClientSettings(), CONFIG.smtp.getAddress());

    // Set up API routes
    logInfo("Binding REST API...");
    router.registerRestInterface!IAuthenticationEndpoint(new AuthenticationEndpoint(), "/api/v1");
    router.registerRestInterface!IUserEndpoint(new UserEndpoint(), "/api/v1");
    router.registerRestInterface!ICSSEndpoint(new CSSEndpoint(), "/api/v1");
    router.registerRestInterface!IGameEndpoint(new GameEndpoint(), "/api/v1");
    
    // Launch server.
    logInfo("Launching server...");
    listenHTTP(CONFIG.bindAddress, router);
    logInfo("Server started on %s!...", CONFIG.bindAddress);
    runApplication();
}
