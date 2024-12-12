#!/usr/bin/env bash

export PATH="${HOME}/intelFPGA_lite/17.0/quartus/bin/:${PATH}"

set -ex

quartus_sh --flow compile Osborne
