library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity osborne_1 is
    port (
        -- Z80 CPU
        reset_n: in std_logic;
        clock_cpu: out std_logic := '0';
        address: out std_logic_vector(15 downto 0);
        data: inout std_logic_vector(7 downto 0);

        -- Clocks
        clock_62ns: in std_logic;
        clock_dot: out std_logic := '1';
        
        -- 4 KiB boot ROM
        boot_rom_read_n: out std_logic;

        -- 64 KiB RAM
        ram_read_n: out std_logic;
        ram_write_n: out std_logic
    );
end osborne_1;

architecture behavior of osborne_1 is
    -- Z80 CPU
    signal mreq_n: std_logic;
    signal iorq_n: std_logic;
    signal rd_n: std_logic;
    signal wr_n: std_logic;
    signal A: std_logic_vector(15 downto 0);

    -- Clocks
    signal clock_div: std_logic_vector(1 downto 0) := "00";

    -- ROM
    signal rom_en_n: std_logic := '0';
    signal rom_has_addr_n: std_logic := '0';
begin
    -- Z80 CPU
    z80a: entity work.T80a port map (
        reset_n => reset_n,
        R800_mode => '0',
        CLK_n => clock_cpu,
        WAIT_n => '1',
        INT_n => '1',
        NMI_n => '1',
        BUSRQ_n => '1',
        MREQ_n => mreq_n,
        IORQ_n => iorq_n,
        rd_n => rd_n,
        WR_n => wr_n,
        A => A,
        D => data
    );
    address <= A;

    -- Clocks
    clock_gen: process(clock_62ns)
    begin
        if rising_edge(clock_62ns) then
            clock_div <= clock_div + 1;
        end if;
    end process;
    clock_cpu <= clock_div(1);
    clock_dot <= not clock_div(0);

    -- ROM (4KiB when ROM_EN_n is low)
    rom_has_addr_n <= rom_en_n or A(15) or A(14) or A(13) or A(12);
    boot_rom_read_n <= mreq_n or rd_n or rom_has_addr_n;

    -- RAM
    ram_read_n <= mreq_n or rd_n or (not rom_has_addr_n);
    ram_write_n <= mreq_n or wr_n or (not rom_has_addr_n);
end;
