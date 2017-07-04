#!/bin/sh
cd /storage
exec env LD_PRELOAD=/opt/makemkv/lib/umask_wrapper.so /opt/makemkv/bin/makemkv
