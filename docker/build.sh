#!/bin/bash
ver=1
name="pgdac_skip_parse"
docker_tag=rkothadi/$name:$ver

# cp from the mac results in fchmod permission denied errors -- ignore those and continue
docker build -t $docker_tag .
