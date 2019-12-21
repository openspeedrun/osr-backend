# OpenSpeedRun
This is the backend system of the OpenSpeedRun server software.

## What is OpenSpeedRun?
OpenSpeedRun is an open source server software suite for hosting [speedrunning](https://en.wikipedia.org/wiki/Speedrun) leaderboards.

This exists in contrast to some propriatary and monolithic software solutions which are generally in use in the speedrunning community.

&nbsp;
## Building OpenSpeedRun

### Toolchain
To build this project, you first need a suitable [D](https://dlang.org/) compiler installed.

We recommend the DMD compiler for debug builds and LDC2 for release builds.

&nbsp;
### Dependencies
OpenSpeedRun depends on the following C libraries and services:
 * OpenSSL
 * MongoDB

Make sure those are installed before building

&nbsp;
### Building
#### Debug
To build a debug build run
```
dub build
```
in the root directory of this project.

#### Release
To build a release build run
```
dub build -b release --compiler=ldc2
```

&nbsp;
## Running OpenSpeedRun

### Configuring the Server
OpenSpeedRun is configured via the `osrconfig.sdl` file, which should either be placed in the same directory as the executable or `/etc/osr/osrconfig.sdl` on POSIX complaint systems.

A new configuration file will automatically be generated if the server finds none.

Configuration is written in [SDLang](https://sdlang.org/).

#### Example
```sdlang
// Email Server Settings
smtp {

  // Email username
  username ""
  
  // Email password
  password ""

  // Email host
  host "localhost"

  // Email port
  port 25

  // Origin email field
  originEmail ""
}

// Authentication settings
auth {
  
  // Allow signups on the server
  allowSignups true
  
  // Enable 2-factor authentication system
  enable2FA true
  
  // Wether to require email verification
  emailVerification false
  
  // Max length of email
  maxEmailLength 72
  
  // Minimum length of email
  minUsernameLength 3
  
  // Maximum length of username
  maxUsernameLength 72
  
  // Minimum password length
  minPasswordLength 8
  
  // Maximum password length
  maxPasswordLength 1024
  
  // Google ReCaptcha Secret
  recaptchaSecret "Secret Here"
  
  // Google ReCaptcha Site Key
  recaptchaSiteKey "Site Key Here"
}

// The local address to bind the server to.
bindAddress "127.0.0.1:8080"

// The MongoDB database connection string
dbConnectionString "mongodb://127.0.0.1"
```

&nbsp;
### Running the server (debug)
To build and run a debug build, just run
```
dub
```
In the project's root directory.

&nbsp;
### Running the server (release)
It is recommended to on Linux, run the server via a systemd unit.

#### Example
Would be present in `/etc/systemd/system/osr.service`
```ini
[Unit]
Description=OpenSpeedRun Server
After=network.target
After=systemd-user-sessions.service
After=network-online.target

[Service]
Type=simple
Restart=always
WorkingDirectory=/opt/osr/osr-backend
ExecStart=/opt/osr/osr-backend

[Install]
WantedBy=multi-user.target
```