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
module api.common;
public import vibe.data.serialization;
public import backend.auth.jwt;
public import vibe.web.rest;
public import vibe.http.common;

/++
    Enum of valid status codes that can be returned from the API
+/
enum StatusCode : string {
    StatusOK = "ok",
    StatusInvalid = "invalid",
    StatusDenied = "access_denied",
    StatusNotFound = "not_found",
    StatusInternalErr = "internal_error"
}

// A log in token is a string
alias Token = string;

/++
    A status without associated data.
+/
struct Status {
    /++
        The status code defining what error has happened
    +/
    StatusCode status;

    /++
        Error message (if any)
    +/
    @optional
    string message = null;

    this(StatusCode code) {
        this.status = code;
    }

    this(StatusCode code, string error) {
        this.status = code;
        this.message = error;
    }

    /++
        Returns explicit error version of status
    +/
    static Status error(StatusCode code, string error) {
        return Status(code, error);
    }
}

/++
    A status is the basic container for API callback information.
+/
struct StatusT(T) {
    /++
        The status code defining what error has happened
    +/
    StatusCode status;

    /++
        Error message (if any)
    +/
    @optional
    string message = null;

    /++
        The data for the status
    +/
    T data;

    this(StatusCode code) {
        this.status = code;
    }
    
    /++
        Returns explicit error version of status
    +/
    static StatusT!T error(StatusCode code, string error) {
        auto status = StatusT!T(code);
        status.message = error;
        return status;
    }

    this(StatusCode code, T data) {
        this.status = code;
        this.data = data;
    }
}