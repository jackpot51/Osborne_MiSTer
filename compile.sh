#!/usr/bin/env bash

export PATH="${HOME}/intelFPGA_lite/17.0/quartus/bin/:${PATH}"

set -ex

make -C testbench build/boot_rom.ihx
cp -v testbench/build/boot_rom.ihx rom/custom_rom.hex

quartus_sh --flow compile Osborne
