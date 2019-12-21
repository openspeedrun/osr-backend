# OpenSpeedRun
This is the backend system of the OpenSpeedRun server software.

## What is OpenSpeedRun?
OpenSpeedRun is an open source (AGPL licensed) server software suite for hosting [speedrunning](https://en.wikipedia.org/wiki/Speedrun) leaderboards.

OpenSpeedRun aims to provide the resources for individuals and organizations to host their own leaderboards for games. 

The base server comes without a frontend; while we do provide an [official frontend](https://github.com/openspeedrun/osr-frontend), OSR can be used headless to store time leaderboards for games directly.

We host an offical instance for general speedrunning at [http://openspeedrun.net](openspeedrun.net/games).

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
#### Notes

The output of the builds are stored in the `out/` directory.

If the directory doesn't exist, it will be created automatically.

The output will be called `osr-server`.

#### Debug
To build a debug build, run the folllowing
```
dub build
```
in the root directory of the project.

#### Release
To build a release build, run the folllowing
```
dub build -b release --compiler=ldc2
```
in the root directory of the project.

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
To build and run a debug build, run the folllowing
```
dub
```
In the project's root directory.

&nbsp;
### Running the server (release)
It is recommended to (on Linux), run the server via a systemd unit.
We also recommend installing osr in to /opt/osr as it's not a system package.

We won't provide Windows Server-specific instructions as Windows Server is not officially supported. The executable should build and run on Windows, but here be dragons.

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
WorkingDirectory=/opt/osr/osr-server
ExecStart=/opt/osr/osr-server

[Install]
WantedBy=multi-user.target
```

Remember to enable and start the server with
```
systemctl enable osr.service
systemctl start osr.service
```
These commands only need to be run once.