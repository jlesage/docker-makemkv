# Docker container for MakeMKV
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/makemkv/latest)](https://hub.docker.com/r/jlesage/makemkv/tags) [![Build Status](https://github.com/jlesage/docker-makemkv/actions/workflows/build-image.yml/badge.svg?branch=master)](https://github.com/jlesage/docker-makemkv/actions/workflows/build-image.yml) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-makemkv.svg)](https://github.com/jlesage/docker-makemkv/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage)

This is a Docker container for [MakeMKV](https://www.makemkv.com).

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

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

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

## Documentation

Full documentation is available at https://github.com/jlesage/docker-makemkv.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-makemkv/issues
