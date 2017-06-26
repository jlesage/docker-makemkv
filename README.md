# Docker container for MakeMKV
[![Docker Automated build](https://img.shields.io/docker/automated/jlesage/makemkv.svg)](https://hub.docker.com/r/jlesage/makemkv/) [![](https://images.microbadger.com/badges/image/jlesage/makemkv.svg)](http://microbadger.com/#/images/jlesage/makemkv "Get your own image badge on microbadger.com") [![Build Status](https://travis-ci.org/jlesage/docker-makemkv.svg?branch=master)](https://travis-ci.org/jlesage/docker-makemkv)

This is a Docker container for MakeMKV.

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on client side) or via any VNC client.

A fully automated mode is also available: insert a DVD or Blu-ray disc into an optical drive and let MakeMKV rips it without any user interaction.

---

[![MakeMKV logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png&w=200)](http://www.makemkv.com/)[![MakeMKV](https://dummyimage.com/400x110/ffffff/575757&text=MakeMKV)](http://www.makemkv.com/)

MakeMKV is your one-click solution to convert video that you own into free and
patents-unencumbered format that can be played everywhere. MakeMKV is a format
converter, otherwise called "transcoder". It converts the video clips from
proprietary (and usually encrypted) disc into a set of MKV files, preserving
most information but not changing it in any way. The MKV format can store
multiple video/audio tracks with all meta-information and preserve chapters.

---

## Quick Start

Launch the MakeMKV docker container with the following command:
```
docker run -d --rm \
    --name=makemkv \
    -p 5800:5800 \
    -p 5900:5900 \
    -v /docker/appdata/makemkv:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/MakeMKV/output:/output:rw \
    --device /dev/sr0 \
    jlesage/makemkv
```

Where:
  - `/docker/appdata/makemkv`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.
  - `$HOME/MakeMKV/output`: This is where extracted videos are written.
  - `/dev/sr0`: This is the optical drive.

Browse to `http://your-host-ip:5800` to access the MakeMKV GUI.  Files from
the host appear under the `/storage` folder in the container.

## Usage

```
docker run [-d] [--rm] \
    --name=makemkv \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/makemkv
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in background.  If not set, the container runs in foreground. |
| --rm      | Automatically remove the container when it exits. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1280` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `768` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Pasword](#vnc-password) section for more details. | (unset) |
|`KEEP_GUIAPP_RUNNING`| When set to `1`, the application will be automatically restarted if it crashes or if user quits it. | `0` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  By default, niceness is not set, meaning that the default niceness of 0 is used.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | (unset) |
|`MAKEMKV_KEY`| MakeMKV registration key to use.  The key is writtent to the configuration file during container startup.  When set to `BETA`, the latest beta key is automatically used.  When set to `UNSET`, no key is automatically written to the configuration file. | `BETA` |
|`AUTO_DISC_RIPPER`| When set to `1`, the automatic disc ripper is enabled. | `0` |
|`AUTO_DISC_RIPPER_EJECT`| When set to `1`, disc is ejected from the drive when ripping is terminated. | `0` |
|`AUTO_DISC_RIPPER_MIN_TITLE_LENGTH`| Titles with a length less than this value are ignored.  Length is in seconds.  By default, no value is set, meaning that value from MakeMKV's configuration file is taken. | (unset) |
|`AUTO_DISC_RIPPER_BD_MODE`| Rip mode of Blu-ray discs.  `mkv` is the default mode, where a set of MKV files are produced.  When set to `backup`, a copy of the (decrypted) file system is created instead. **NOTE**: This applies to Blu-ray discs only.  For DVD discs, MKV files are always produced. | `mkv` |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible by the application. |
|`/output`| rw | This is where extracted videos are written. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 5800 | Mandatory | Port used to access the application's GUI via the web interface. |
| 5900 | Mandatory | Port used to access the application's GUI via the VNC protocol. |
| 51000 | Optional | Port used by the streaming service. |

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming the host is mapped to the same ports as the container, the graphical
interface of the application can be accessed via:

  * A web browser:
```
http://<HOST IP ADDR>:5800
```

  * Any VNC client:
```
<HOST IP ADDR>:5900
```

If different ports are mapped to the host, make sure they respect the
following formula:

    VNC_PORT = HTTP_PORT + 100

This is to make sure accessing the GUI with a web browser can be done without
specifying the VNC port manually.  If this is not possible, then specify
explicitly the VNC port like this:

    http://<HOST IP ADDR>:5800/?port=<VNC PORT>

## VNC Password

To restrict access to your application, a password can be specified.  This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
  This file should contains the password (in clear).  During the container
  startup, content of the file is obfuscated and renamed to `.vncpass`.

**NOTE**: This is a very basic way to restrict access to the application and it
should not be considered as secure in any way.

## Access to Optical Drive(s)

By default, a Docker container doesn't have access to host's devices.  However,
access to one or more device can be granted with the `--device DEV` parameter.

Optical drives usually have `/dev/srX` as device.  For example, the first drive
is `/dev/sr0`, the second `/dev/sr1`, and so onxe.  To allow MakeMKV to access
the first drive, this parameter is needed:
```
--device /dev/sr0
```

## Automatic Disc Ripper

This container has an automatic disc ripper built-in.  When enabled, any DVD or
Blu-ray video disc inserted into an optical drive is automatically ripped.  In
other words, MakeMKV decrypts and extracts all titles (such as the main movie,
bonus features, etc) from the disc to MKV files.

To enable the automatic disc ripper, set the environment variable
`AUTO_DISC_RIPPER` to `1`.

To eject the disc from the drive when ripping is terminated, set the environment
variable `AUTO_DISC_RIPPER_EJECT` to `1`.

See the [Environment Variables](#environment-variables) section for details
about setting environment variables.

**NOTE**: All titles, audio tracks, chapters, subtitles, etc are
        extracted/preserved.

**NOTE**: Titles and audio tracks are kept in their original format.  They are
        not transcoded or converted to other formats or into smaller sizes.

**MOTE**: Ripped Blu-ray discs can take a large amount of disc space (~40GB).

**NOTE**: MKV Files are written to the `/output` folder of the container.

**NOTE**: The automatic disc ripper processes all available optical drives.

## Troubleshooting

### Expired Beta Key

If the beta key is expired, just restart the container to automatically fetch
and install the latest one.

**NOTE**: For this solution to work, the `MAKEMKV_KEY` environment variable must
be set to `BETA`.  See the [Environment Variables](#environment-variables)
section for more details.

[TimeZone]: http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
