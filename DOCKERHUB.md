# Docker container for MakeMKV
[![Release](https://img.shields.io/github/release/jlesage/docker-makemkv.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-makemkv/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/makemkv/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/makemkv?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/makemkv?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/makemkv)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-makemkv/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-makemkv/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-makemkv)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [MakeMKV](https://www.makemkv.com).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

A fully automated mode is also available: insert a DVD or Blu-ray disc into an
optical drive and let MakeMKV rips it without any user interaction.

> This Docker container is entirely unofficial and not made by the creators of
> MakeMKV.

---

[![MakeMKV logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png&w=110)](https://www.makemkv.com)[![MakeMKV](https://images.placeholders.dev/?width=224&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=MakeMKV&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.makemkv.com)

MakeMKV is your one-click solution to convert video that you own into free and
patents-unencumbered format that can be played everywhere. MakeMKV is a format
converter, otherwise called "transcoder". It converts the video clips from
proprietary (and usually encrypted) disc into a set of MKV files, preserving
most information but not changing it in any way. The MKV format can store
multiple video/audio tracks with all meta-information and preserve chapters.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

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

  - `/docker/appdata/makemkv`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.
  - `/home/user/MakeMKV/output`: This is where extracted videos are written.
  - `/dev/sr0`: First linux device file corresponding to the optical drive.
  - `/dev/sg2`: Second linux device file corresponding to the optical drive.

Access the MakeMKV GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-makemkv.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-makemkv/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
