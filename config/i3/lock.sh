#!/usr/bin/env bash

dunstctl set-paused true
trap 'dunstctl set-paused false' EXIT

i3lock --nofork -c 000000
