# Docker container for MakeMKV
[![Release](https://img.shields.io/github/release/jlesage/docker-makemkv.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-makemkv/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/makemkv/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/makemkv?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/makemkv?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-makemkv/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-makemkv/actions/workflows/build-image.yml)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This project implements a Docker container for [MakeMKV](https://www.makemkv.com).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

A fully automated mode is also available: insert a DVD or Blu-ray disc into an
optical drive and let MakeMKV rips it without any user interaction.

---

[![MakeMKV logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png&w=110)](https://www.makemkv.com)[![MakeMKV](https://images.placeholders.dev/?width=224&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=MakeMKV&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.makemkv.com)

MakeMKV is your one-click solution to convert video that you own into free and
patents-unencumbered format that can be played everywhere. MakeMKV is a format
converter, otherwise called "transcoder". It converts the video clips from
proprietary (and usually encrypted) disc into a set of MKV files, preserving
most information but not changing it in any way. The MKV format can store
multiple video/audio tracks with all meta-information and preserve chapters.

---

## Table of Content

   * [Quick Start](#quick-start)
   * [Usage](#usage)
      * [Environment Variables](#environment-variables)
         * [Deployment Considerations](#deployment-considerations)
      * [Data Volumes](#data-volumes)
      * [Ports](#ports)
      * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
   * [Docker Compose File](#docker-compose-file)
   * [Docker Image Versioning](#docker-image-versioning)
   * [Docker Image Update](#docker-image-update)
      * [Synology](#synology)
      * [unRAID](#unraid)
   * [User/Group IDs](#usergroup-ids)
   * [Accessing the GUI](#accessing-the-gui)
   * [Security](#security)
      * [SSVNC](#ssvnc)
      * [Certificates](#certificates)
      * [VNC Password](#vnc-password)
      * [Web Authentication](#web-authentication)
         * [Configuring Users Credentials](#configuring-users-credentials)
   * [Reverse Proxy](#reverse-proxy)
      * [Routing Based on Hostname](#routing-based-on-hostname)
      * [Routing Based on URL Path](#routing-based-on-url-path)
   * [Shell Access](#shell-access)
   * [Access to Optical Drive(s)](#access-to-optical-drives)
   * [Automatic Disc Ripper](#automatic-disc-ripper)
   * [Hooks](#hooks)
   * [Troubleshooting](#troubleshooting)
      * [Expired Beta Key](#expired-beta-key)
   * [Support or Contact](#support-or-contact)

## Quick Start

> [!IMPORTANT]
> The Docker command provided in this quick start is given as an example and
> parameters should be adjusted to your need.

Launch the MakeMKV docker container with the following command:
```shell
docker run -d \
    --name=makemkv \
    -p 5800:5800 \
    -v /docker/appdata/makemkv:/config:rw \
    -v /home/user:/storage:ro \
    -v /home/user/MakeMKV/output:/output:rw \
    --device /dev/sr0 \
    --device /dev/sg2 \
    jlesage/makemkv
```

Where:

  - `/docker/appdata/makemkv`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `/home/user`: This location contains files from your host that need to be accessible to the application.
  - `/home/user/MakeMKV/output`: This is where extracted videos are written.
  - `/dev/sr0`: This is the first Linux device file representing the optical drive.
  - `/dev/sg2`: This is the second Linux device file representing the optical drive.

Browse to `http://your-host-ip:5800` to access the MakeMKV GUI.
Files from the host appear under the `/storage` folder in the container.

## Usage

```shell
docker run [-d] \
    --name=makemkv \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/makemkv
```

| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background. If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container. See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container). See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host). See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable). Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as. See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as. See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (no value) |
|`UMASK`| Mask that controls how permissions are set for newly created files and folders. The value of the mask is in octal notation. By default, the default umask value is `0022`, meaning that newly created files and folders are readable by everyone, but only writable by the owner. See the online umask calculator at http://wintelguy.com/umask-calc.pl. | `0022` |
|`LANG`| Set the [locale](https://en.wikipedia.org/wiki/Locale_(computer_software)), which defines the application's language, **if supported**. Format of the locale is `language[_territory][.codeset]`, where language is an [ISO 639 language code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes), territory is an [ISO 3166 country code](https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes) and codeset is a character set, like `UTF-8`. For example, Australian English using the UTF-8 encoding is `en_AU.UTF-8`. | `en_US.UTF-8` |
|`TZ`| [TimeZone](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones) used by the container. Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted when it crashes or terminates. | `0` |
|`APP_NICENESS`| Priority at which the application should run. A niceness value of -20 is the highest priority and 19 is the lowest priority. The default niceness value is 0. **NOTE**: A negative niceness (priority increase) requires additional permissions. In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | `0` |
|`INSTALL_PACKAGES`| Space-separated list of packages to install during the startup of the container. List of available packages can be found at https://pkgs.alpinelinux.org. **ATTENTION**: Container functionality can be affected when installing a package that overrides existing container files (e.g. binaries). | (no value) |
|`PACKAGES_MIRROR`| Mirror of the repository to use when installing packages. List of mirrors is available at https://mirrors.alpinelinux.org. | (no value) |
|`CONTAINER_DEBUG`| Set to `1` to enable debug logging. | `0` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1920` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `1080` |
|`DARK_MODE`| When set to `1`, dark mode is enabled for the application. | `0` |
|`WEB_AUDIO`| When set to `1`, audio support is enabled, meaning that any audio produced by the application is played through the browser. Note that audio is not supported for VNC clients. | `0` |
|`WEB_AUTHENTICATION`| When set to `1`, the application's GUI is protected via a login page when accessed via a web browser. Access is allowed only when providing valid credentials. **NOTE**: This feature requires secure connection (`SECURE_CONNECTION` environment variable) to be enabled. | `0` |
|`WEB_AUTHENTICATION_TOKEN_VALIDITY_TIME`| The lifetime of a token, in hours. A token is attributed to the user after a successful login. As long as the token is valid, user can access the application's GUI without having to log in again. Once the token expires, the login page is prompted again. | `24` |
|`WEB_AUTHENTICATION_USERNAME`| Optional username to configure for the web authentication. This is a quick and easy way to configure credentials for a single user. To configure credentials in a more secure way, or to add more users, see the [Web Authentication](#web-authentication) section. | (no value) |
|`WEB_AUTHENTICATION_PASSWORD`| Optional password to configure for the web authentication. This is a quick and easy way to configure credentials for a single user. To configure credentials in a more secure way, or to add more users, see the [Web Authentication](#web-authentication) section. | (no value) |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via a web browser or VNC client). See the [Security](#security) section for more details. | `0` |
|`SECURE_CONNECTION_VNC_METHOD`| Method used to perform the secure VNC connection. Possible values are `SSL` or `TLS`. See the [Security](#security) section for more details. | `SSL` |
|`SECURE_CONNECTION_CERTS_CHECK_INTERVAL`| Interval, in seconds, at which the system verifies if web or VNC certificates have changed. When a change is detected, the affected services are automatically restarted. A value of `0` disables the check. | `60` |
|`WEB_LISTENING_PORT`| Port used by the web server to serve the UI of the application. This port is used internally by the container and it is usually not required to be changed. By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument). However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers. **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over HTTP/HTTPs. | `5800` |
|`VNC_LISTENING_PORT`| Port used by the VNC server to serve the UI of the application. This port is used internally by the container and it is usually not required to be changed. By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument). However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers. **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over VNC. | `5900` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI. See the [VNC Password](#vnc-password) section for more details. | (no value) |
|`ENABLE_CJK_FONT`| When set to `1`, open-source computer font `WenQuanYi Zen Hei` is installed. This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`MAKEMKV_KEY`| MakeMKV registration key to use. The key is written to the configuration file during container startup. When set to `BETA`, the latest beta key is automatically used. When set to `UNSET`, no key is automatically written to the configuration file. | `BETA` |
|`MAKEMKV_GUI`| Setting this to `1` enables the MakeMKV, `0` disables it. | `1` |
|`AUTO_DISC_RIPPER`| When set to `1`, the automatic disc ripper is enabled. | `0` |
|`AUTO_DISC_RIPPER_MAKEMKV_PROFILE`| Filename of the custom MakeMKV profile the automatic disc ripper should use. The profile is expected to be found under the `/config` folder of the container, unless an absolute path is specified. | (no value) |
|`AUTO_DISC_RIPPER_EJECT`| When set to `1`, disc is ejected from the drive when ripping is terminated. | `0` |
|`AUTO_DISC_RIPPER_PARALLEL_RIP`| When set to `1`, discs from all available optical drives are ripped in parallel. Else, each disc from optical drives is ripped one at time. | `0` |
|`AUTO_DISC_RIPPER_INTERVAL`| Interval, in seconds, the automatic disc ripper checks for the presence of a DVD/Blu-ray discs. | `5` |
|`AUTO_DISC_RIPPER_MIN_TITLE_LENGTH`| Titles with a length less than this value are ignored. Length is in seconds. By default, no value is set, meaning that value from MakeMKV's configuration file is taken. | (no value) |
|`AUTO_DISC_RIPPER_BD_MODE`| Rip mode of Blu-ray discs. `mkv` is the default mode, where a set of MKV files are produced. When set to `backup`, a copy of the (decrypted) file system of the disc is created instead. | `mkv` |
|`AUTO_DISC_RIPPER_DVD_MODE`| Rip mode of DVD discs. `mkv` is the default mode, where a set of MKV files are produced. When set to `backup`, a copy of the (decrypted) file system of the disc is instead created as an ISO file. | `mkv` |
|`AUTO_DISC_RIPPER_FORCE_UNIQUE_OUTPUT_DIR`| When set to `0`, files are written to `/output/DISC_LABEL/`, where `DISC_LABEL` is the label/name of the disc. If this directory exists, then files are written to `/output/DISC_LABEL-XXXXXX`, where `XXXXXX` are random readable characters. When set to `1`, the `/output/DISC_LABEL-XXXXXX` pattern is always used. | `0` |
|`AUTO_DISC_RIPPER_NO_GUI_PROGRESS`| When set to `1`, progress of discs ripped by the automatic disc ripper is not shown in the MakeMKV GUI. | `0` |

#### Deployment Considerations

Many tools used to manage Docker containers extract environment variables
defined by the Docker image and use them to create/deploy the container. For
example, this is done by:
  - The Docker application on Synology NAS
  - The Container Station on QNAP NAS
  - Portainer
  - etc.

While this can be useful for the user to adjust the value of environment
variables to fit its needs, it can also be confusing and dangerous to keep all
of them.

A good practice is to set/keep only the variables that are needed for the
container to behave as desired in a specific setup. If the value of variable is
kept to its default value, it means that it can be removed. Keep in mind that
all variables are optional, meaning that none of them is required for the
container to start.

Removing environment variables that are not needed provides some advantages:

  - Prevents keeping variables that are no longer used by the container. Over
    time, with image updates, some variables might be removed.
  - Allows the Docker image to change/fix a default value. Again, with image
    updates, the default value of a variable might be changed to fix an issue,
    or to better support a new feature.
  - Prevents changes to a variable that might affect the correct function of
    the container. Some undocumented variables, like `PATH` or `ENV`, are
    required to be exposed, but are not meant to be changed by users. However,
    container management tools still show these variables to users.
  - There is a bug with the Container Station on QNAP and the Docker application
    on Synology, where an environment variable without value might not be
    allowed. This behavior is wrong: it's absolutely fine to have a variable
    without value. In fact, this container does have variables without value by
    default. Thus, removing unneeded variables is a good way to prevent
    deployment issue on these devices.

### Data Volumes

The following table describes data volumes used by the container. The mappings
are set via the `-v` parameter. Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, states, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible to the application. |
|`/output`| rw | This is where extracted videos are written. |

### Ports

Here is the list of ports used by the container.

When using the default bridge network, ports can be mapped to the host via the
`-p` parameter (one per port mapping). Each mapping is defined with the
following format: `<HOST_PORT>:<CONTAINER_PORT>`. The port number used inside
the container might not be changeable, but you are free to use any port on the
host side.

See the [Docker Container Networking](https://docs.docker.com/config/containers/container-networking)
documentation for more details.

| Port | Protocol | Mapping to host | Description |
|------|----------|-----------------|-------------|
| 5800 | TCP | Optional | Port to access the application's GUI via the web interface. Mapping to the host is optional if access through the web interface is not wanted. For a container not using the default bridge network, the port can be changed with the `WEB_LISTENING_PORT` environment variable. |
| 5900 | TCP | Optional | Port to access the application's GUI via the VNC protocol. Mapping to the host is optional if access through the VNC protocol is not wanted. For a container not using the default bridge network, the port can be changed with the `VNC_LISTENING_PORT` environment variable. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container. The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```shell
docker stop makemkv
```

  2. Remove the container:
```shell
docker rm makemkv
```

  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

> [!NOTE]
> Since all application's data is saved under the `/config` container folder,
> destroying and re-creating a container is not a problem: nothing is lost and
> the application comes back with the same state (as long as the mapping of the
> `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs. Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  makemkv:
    image: jlesage/makemkv
    ports:
      - "5800:5800"
    volumes:
      - "/docker/appdata/makemkv:/config:rw"
      - "/home/user:/storage:ro"
      - "/home/user/MakeMKV/output:/output:rw"
    devices:
      - "/dev/sr0:/dev/sr0"
      - "/dev/sg2:/dev/sg2"
```

## Docker Image Versioning

Each release of a Docker image is versioned. Prior to october 2022, the
[semantic versioning](https://semver.org) was used as the versioning scheme.

Since then, versioning scheme changed to
[calendar versioning](https://calver.org). The format used is `YY.MM.SEQUENCE`,
where:
  - `YY` is the zero-padded year (relative to year 2000).
  - `MM` is the zero-padded month.
  - `SEQUENCE` is the incremental release number within the month (first release
    is 1, second is 2, etc).

## Docker Image Update

Because features are added, issues are fixed, or simply because a new version
of the containerized application is integrated, the Docker image is regularly
updated. Different methods can be used to update the Docker image.

The system used to run the container may have a built-in way to update
containers. If so, this could be your primary way to update Docker images.

An other way is to have the image be automatically updated with [Watchtower].
Watchtower is a container-based solution for automating Docker image updates.
This is a "set and forget" type of solution: once a new image is available,
Watchtower will seamlessly perform the necessary steps to update the container.

Finally, the Docker image can be manually updated with these steps:

  1. Fetch the latest image:
```shell
docker pull jlesage/makemkv
```

  2. Stop the container:
```shell
docker stop makemkv
```

  3. Remove the container:
```shell
docker rm makemkv
```

  4. Create and start the container using the `docker run` command, with the
the same parameters that were used when it was deployed initially.

[Watchtower]: https://github.com/containrrr/watchtower

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/makemkv`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete. A notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your MakeMKV container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Reset* (or *Action*->*Clear* if
      you don't have the latest *Docker* application). This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container. For example, the user within the container may not
exist on the host. This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```text
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:

```text
http://<HOST IP ADDR>:5800
```

  * Any VNC client:

```text
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable. See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser. All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL. Note that
few VNC clients support this method. [SSVNC] is one of them.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html

### SSVNC

[SSVNC] is a VNC viewer that adds encryption security to VNC connections.

While the Linux version of [SSVNC] works well, the Windows version has some
issues. At the time of writing, the latest version `1.0.30` is not functional,
as a connection fails with the following error:
```text
ReadExact: Socket error while reading
```
However, for your convenience, an unofficial and working version is provided
here:

https://github.com/jlesage/docker-baseimage-gui/raw/master/tools/ssvnc_windows_only-1.0.30-r1.zip

The only difference with the official package is that the bundled version of
`stunnel` has been upgraded to version `5.49`, which fixes the connection
problems.

### Certificates

Here are the certificate files needed by the container. By default, when they
are missing, self-signed certificates are generated and used. All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

> [!TIP]
> To prevent any certificate validity warnings/errors from the browser or VNC
> client, make sure to supply your own valid certificates.

> [!NOTE]
> Certificate files are monitored and relevant daemons are automatically
> restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified. This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
    This file should contain the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure the access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

> [!CAUTION]
> Password is limited to 8 characters. This limitation comes from the Remote
> Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see section
> [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)). Any characters
> beyond the limit are ignored.

### Web Authentication

Access to the application's GUI via a web browser can be protected with a login
page. When web authentication is enabled, users have to provide valid
credentials, otherwise access is denied.

Web authentication can be enabled by setting the `WEB_AUTHENTICATION`
environment variable to `1`.

See the [Environment Variables](#environment-variables) section for more details
on how to set an environment variable.

> [!IMPORTANT]
> Secure connection must also be enabled to use web authentication.
> See the [Security](#security) section for more details.

#### Configuring Users Credentials

Two methods can be used to configure users credentials:

  1. Via container environment variables.
  2. Via password database.

Containers environment variables can be used to quickly and easily configure
a single user. Username and pasword are defined via the following environment
variables:
  - `WEB_AUTHENTICATION_USERNAME`
  - `WEB_AUTHENTICATION_PASSWORD`

See the [Environment Variables](#environment-variables) section for more details
on how to set an environment variable.

The second method is more secure and allows multiple users to be configured.
The usernames and password hashes are saved into a password database, located at
`/config/webauth-htpasswd` inside the container. This database file has the
same format as htpasswd files of the Apache HTTP server. Note that password
themselves are not saved into the database, but only their hash. The bcrypt
password hashing function is used to generate hashes.

Users are managed via the `webauth-user` tool included in the container:
  - To add a user password: `docker exec -ti <container name or id> webauth-user add <username>`.
  - To update a user password: `docker exec -ti <container name or id> webauth-user update <username>`.
  - To remove a user: `docker exec <container name or id> webauth-user del <username>`.
  - To list users: `docker exec <container name or id> webauth-user user`.

## Reverse Proxy

The following sections contain NGINX configurations that need to be added in
order to reverse proxy to this container.

A reverse proxy server can route HTTP requests based on the hostname or the URL
path.

### Routing Based on Hostname

In this scenario, each hostname is routed to a different application/container.

For example, let's say the reverse proxy server is running on the same machine
as this container. The server would proxy all HTTP requests sent to
`makemkv.domain.tld` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-makemkv {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	server_name makemkv.domain.tld;

	location / {
	        proxy_pass http://docker-makemkv;
	}

	location /websockify {
		proxy_pass http://docker-makemkv;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_read_timeout 86400;
	}

	# Needed when audio support is enabled.
	location /websockify-audio {
		proxy_pass http://docker-makemkv;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_read_timeout 86400;
	}
}

```

### Routing Based on URL Path

In this scenario, the hostname is the same, but different URL paths are used to
route to different applications/containers.

For example, let's say the reverse proxy server is running on the same machine
as this container. The server would proxy all HTTP requests for
`server.domain.tld/makemkv` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-makemkv {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	location = /makemkv {return 301 $scheme://$http_host/makemkv/;}
	location /makemkv/ {
		proxy_pass http://docker-makemkv/;
		# Uncomment the following line if your Nginx server runs on a port that
		# differs from the one seen by external clients.
		#port_in_redirect off;
		location /makemkv/websockify {
			proxy_pass http://docker-makemkv/websockify/;
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_read_timeout 86400;
		}
	}
}

```
## Shell Access

To get shell access to the running container, execute the following command:

```shell
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation.

## Access to Optical Drive(s)

By default, a Docker container doesn't have access to host's devices. However,
access to one or more devices can be granted with the `--device DEV` parameter.

In the Linux world, an optical drive is represented by two different device
files: `/dev/srX` and `/dev/sgY`, where `X` and `Y` are numbers.

For best performance, it is recommended to expose both these devices to the
container. For example, for an optical drive represented by `/dev/sr0` and
`/dev/sg1`, the following parameters would be added to the `docker run`
command:
```
--device /dev/sr0 --device /dev/sg1
```

> [!NOTE]
> For an optical drive to be detected by MakeMKV, it is mandatory to
> expose `/dev/sgY` to the container. `/dev/srX` is optional, but performance
> could be affected.

The easiest way to determine the right Linux devices to expose is to run the
container (without `--device` parameter) and look at its log: during the
startup, messages similar to these ones are outputed:
```
[cont-init   ] 54-check-optical-drive.sh: looking for usable optical drives...
[cont-init   ] 54-check-optical-drive.sh: found optical drive 'hp HLDS DVDRW GUD1N LD02' [/dev/sr0, /dev/sg3]
[cont-init   ] 54-check-optical-drive.sh:   [ OK ]   associated SCSI Generic (sg) device detected: /dev/sg3.
[cont-init   ] 54-check-optical-drive.sh:   [ ERR ]  the host device /dev/sg3 is not exposed to the container.
[cont-init   ] 54-check-optical-drive.sh:   [ OK ]   associated SCSI CD-ROM (sr) device detected: /dev/sr0.
[cont-init   ] 54-check-optical-drive.sh:   [ WARN ] the host device /dev/sr0 is not exposed to the container.
[cont-init   ] 54-check-optical-drive.sh:            performance or ability to use the device will suffer.
[cont-init   ] 54-check-optical-drive.sh: no usable optical drives found.
```

In this case, it's clearly indicated that `/dev/sr0` and `/dev/sg3` need to be
exposed to the container.

> [!NOTE]
> The container's log can be viewed by running the command
> `docker logs <container name>`.

Alternatively, the devices can be found by executing the following command on
the **host**:

```
lsscsi -g
```

From the command's output, the last two columns associated to the optical drive
indicate the Linux devices that should be exposed to the container. In the
following output example, `/dev/sr0` and `/dev/sg3` would be exposed:

```
[0:0:0:0]    disk    ATA      TOSHIBA DT01ACA0 A800  /dev/sda   /dev/sg0
[1:0:0:0]    disk    ATA      ST3500418AS      HP34  /dev/sdb   /dev/sg1
[2:0:0:0]    disk    ATA      WDC WD6401AALS-0 3B01  /dev/sdc   /dev/sg2
[4:0:0:0]    cd/dvd  hp HLDS  DVDRW  GUD1N     LD02  /dev/sr0   /dev/sg3
```

## Automatic Disc Ripper

This container has an automatic disc ripper built-in. When enabled, any DVD or
Blu-ray video disc inserted into an optical drive is automatically ripped. In
other words, MakeMKV decrypts and extracts all titles (such as the main movie,
bonus features, etc) from the disc to MKV files.

To enable the automatic disc ripper, set the environment variable
`AUTO_DISC_RIPPER` to `1`.

To eject the disc from the drive when ripping is terminated, set the environment
variable `AUTO_DISC_RIPPER_EJECT` to `1`.

If multiple drives are available, discs can be ripped simultaneously by
setting the environment variable `AUTO_DISC_RIPPER_PARALLEL_RIP` to `1`.

See the [Environment Variables](#environment-variables) section for details
about setting environment variables.

> [!NOTE]
> All titles, audio tracks, chapters, subtitles, etc are extracted/preserved.

> [!NOTE]
> Titles and audio tracks are kept in their original format. They are not
> transcoded or converted to other formats or into smaller sizes.

> [!NOTE]
> Ripped Blu-ray discs can take a large amount of disc space (~40GB).

> [!NOTE]
> MKV Files are written to the `/output` folder of the container.

> [!NOTE]
> The automatic disc ripper processes all available optical drives.

> [!NOTE]
> When parallel mode is enabled (`AUTO_DISC_RIPPER_PARALLEL_RIP` is set to `1`),
> it is recommended, to minimize impact on ripping speed, to increase the
> interval at which the presence of new discs is checked
> (`AUTO_DISC_RIPPER_INTERVAL`).

## Hooks

Custom actions can be performed at different disc ripping stages using hooks.
Hooks are shell scripts executed by both the MakeMKV GUI and the automatic
disc ripper.

> [!NOTE]
> Hooks are always invoked via `/bin/sh`, ignoring any shebang the script may
> have.

Hooks are optional and by default no one is defined. A hook is defined and
executed when a script is found at a specific location.

The following table describe available hooks:

| Container location | Description | Parameter(s) |
|--------------------|-------------|--------------|
| `/config/hooks/automatic_disc_ripper_started.sh` | Hook executed when the automatic disc ripper starts. | None |
| `/config/hooks/disc_rip_started.sh` | Hook executed when the automatic disc ripper started to rip a disc. | The first argument is the MakeMKV drive ID. The second argument is the disc label. Finally, the third argument is the output directory. |
| `/config/hooks/disc_rip_terminated.sh` | Hook executed when the automatic disc ripper terminated to rip a disc. | The first argument is the MakeMKV drive ID. The second argument is the disc label. The third third argument is the output directory. Finally, the fourth argument is the status (`SUCCESS` or `FAILURE`). |
| `/config/hooks/disc_rip_skipped.sh` | Hook executed when the automatic disc ripper skipped a disc. | The first argument is the MakeMKV drive ID. The second argument is the disc label. Finally, the third argument is the reason. The reason can have the following values: `ALREADY_PROCESSED`, `NOT_VIDEO_DISC` and `SERVICE_FIRST_RUN`. |
| `/config/hooks/disc_eject_failed.sh` | Hook executed when the automatic disc ripper failed to eject a disc. | The first argument is the MakeMKV drive ID. The second argument is the error message. |
| `/config/hooks/gui_disc_rip_started.sh` | Hook executed when a disc rip has been started from MakeMKV GUI. | The first argument is the disc label. The second argument is the output directory. |
| `/config/hooks/gui_disc_rip_terminated.sh` | Hook executed when a disc rip from the MakeMKV GUI has been completed. | The first argument is the disc label. The second argument is the output directory. The third argument is the status (`SUCCESS` or `FAILURE`). Finally, the fourth argument is the message associated to the status. |
| `/config/hooks/gui_raw.sh` | This hook is executed everytime a status is provided by MakeMKV. It can be used for debugging purpose. | The first argument is the status code. The second argument is the text associated to the status code. |

During the first start of the container, example hooks are installed in the
`/config/hooks/` folder of the container. Example scripts have the suffix
`.example`. These are good starting point for creating custom scripts.

> [!NOTE]
> Keep in mind that this container has the minimal set of packages required to
> run MakeMKV. If a hook requires additional software, consider using the
> `INSTALL_PACKAGES` environment variable to install any missing packages. See
> the [Environment Variables](#environment-variables) section for more details.

## Troubleshooting

### Expired Beta Key

If the beta key is expired, just restart the container to automatically fetch
and install the latest one.

> [!NOTE]
> Once beta key expires, it can take few days before a new key is made available
> by the author of MakeMKV. During this time, the application is not functional.

> [!NOTE]
> For this solution to work, the `MAKEMKV_KEY` environment variable must be set
> to `BETA`. See the [Environment Variables](#environment-variables) section for
> more details.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-makemkv/issues
