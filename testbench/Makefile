CC=sdcc -mz80 --code-loc 0 --data-loc 0 --no-std-crt0 --sdcccall 1
GHDL=ghdl-llvm
GHDL_ARGS=-fsynopsys --std=08 --workdir=build

all: build/boot_rom.txt build/char_rom.txt
	mkdir -p build
	$(GHDL) -a $(GHDL_ARGS) ../rtl/MC6821/pia6821.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80_Pack.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80_ALU.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80_MCode.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80_Reg.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/T80/T80a.vhd
	$(GHDL) -a $(GHDL_ARGS) ../rtl/osborne_1.vhd
	$(GHDL) -a $(GHDL_ARGS) ram.vhd
	$(GHDL) -a $(GHDL_ARGS) rom.vhd
	$(GHDL) -a $(GHDL_ARGS) rom_async.vhd
	$(GHDL) -a $(GHDL_ARGS) testbench.vhd
	$(GHDL) -e $(GHDL_ARGS) testbench
	$(GHDL) -r $(GHDL_ARGS) testbench --stop-time=200ms --vcd=build/testbench.vcd

gtkwave:
	gtkwave build/testbench.vcd

view:
	cargo run --release --manifest-path viewer/Cargo.toml -- build/testbench.vcd

build/%.rel: %.asm
	mkdir -p build
	sdasz80 -o $@ $<

build/%.ihx: build/%.rel
	$(CC) -o $@ $<

build/%.bin: build/%.ihx
	objcopy -Iihex -Obinary --gap-fill=0x00 --pad-to=4096 $< $@

build/%.txt: build/%.bin
	xxd -b -c 1 $< | cut -d ' ' -f 2 > $@

build/boot_rom.ihx: ../rom/boot_rom.hex
	cp -v $< $@

build/char_rom.ihx: ../rom/char_rom.hex
	cp -v $< $@

clean:
	rm -rf build
