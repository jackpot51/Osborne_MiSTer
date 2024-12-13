library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use std.textio.all;

entity testbench is
end testbench;

architecture behavior of testbench is
    -- Z80
    signal RESET_n: std_logic := '0';
    signal R800_mode: std_logic := '0';
    signal CLK_n: std_logic := '0';
    signal WAIT_n: std_logic := '1';
    signal INT_n: std_logic := '1';
    signal NMI_n: std_logic := '1';
    signal BUSRQ_n: std_logic := '1';
    signal MREQ_n: std_logic;
    signal IORQ_n: std_logic;
    signal RD_n: std_logic;
    signal WR_n: std_logic;
    signal ADDR: std_logic_vector(15 downto 0);
    signal DATA: std_logic_vector(7 downto 0);
    -- Clocks
    signal CLK_62ns: std_logic := '0';
    signal CLK_DOT: std_logic := '1';
    signal CLK_MEM: std_logic := '0';
    signal CLK_CHAR: std_logic := '0';
    -- ROM
    signal ROM_EN_n: std_logic := '0';
    signal ROM_HAS_ADDR_n: std_logic := '0';
    -- Video
    signal HSYNC: std_logic := '0';
    signal VSYNC: std_logic := '1';
    -- Starting X at 1 keeps it synced with clk_char, for unknown reasons
    signal X: unsigned(9 downto 0) := to_unsigned(1, 10);
    signal Y: unsigned(8 downto 0) := to_unsigned(0, 9);
    signal CHAR_ROW: std_logic_vector(3 downto 0) := (others => '0');
    signal VRAM_ROW: std_logic_vector(4 downto 0) := (others => '0');
    signal VRAM_DATA: std_logic_vector(7 downto 0);
    signal CHAR_DATA: std_logic_vector(7 downto 0);
    signal VIDEO: std_logic := '0';
begin
    -- Z80

    RESET_n <= '1' after 500 ns;
    CLK_62ns <= not CLK_62ns after 62 ns;

    z80a: entity work.T80a port map (
        RESET_n => RESET_n,
        R800_mode => R800_mode,
        CLK_n => CLK_n,
        WAIT_n => WAIT_n,
        INT_n => INT_n,
        NMI_n => NMI_n,
        BUSRQ_n => BUSRQ_n,
        MREQ_n => MREQ_n,
        IORQ_n => IORQ_n,
        RD_n => RD_n,
        WR_n => WR_n,
        A => ADDR,
        D => DATA
    );

    -- Clocks

    clock_cpu: process (CLK_DOT)
    begin
        if rising_edge(CLK_DOT) then
            CLK_n <= not CLK_n;
        end if;
    end process;

    clock_mem: process(CLK_n)
    begin
        if falling_edge(CLK_n) then
            CLK_MEM <= not CLK_MEM;
        end if;
    end process;

    clock_char: process(CLK_MEM)
    begin
        if falling_edge(CLK_MEM) then
            CLK_CHAR <= not CLK_CHAR;
        end if;
    end process;

    -- ROM (4KiB when ROM_EN_n is low)

    ROM_HAS_ADDR_n <= ROM_EN_n or ADDR(15) or ADDR(14) or ADDR(13) or ADDR(12);
    boot_rom: entity work.rom
    generic map (
        g_ADDR_WIDTH => 12,
        g_MEM_IMG_FILENAME => "build/boot.txt"
    )
    port map (
        CLK_n => CLK_n,
        RD_n => RD_n or ROM_HAS_ADDR_n,
        ADDR => ADDR(11 downto 0),
        DATA => DATA
    );

    -- RAM

    ram: entity work.ram
    generic map (
        g_ADDR_WIDTH => 16
    )
    port map (
        A_CLK_n => CLK_n,
        A_RD_n => RD_n or (not ROM_HAS_ADDR_n),
        A_WR_n => WR_n or (not ROM_HAS_ADDR_n),
        A_ADDR => ADDR,
        A_DATA => DATA,
        --TODO: best clock to use?
        B_CLK_n => not CLK_62ns,
        B_RD_n => '0',
        B_WR_n => '1',
        B_ADDR(6 downto 0) => std_logic_vector(X(9 downto 3)),
        B_ADDR(11 downto 7) => VRAM_ROW(4 downto 0),
        B_ADDR(15 downto 12) => "1111",
        B_DATA => VRAM_DATA
    );

    -- Video

    character_rom: entity work.rom_async
    generic map (
        g_ADDR_WIDTH => 11,
        g_MEM_IMG_FILENAME => "build/character_rom.txt"
    )
    port map (
        ADDR(6 downto 0) => VRAM_DATA(6 downto 0),
        ADDR(10 downto 7) => CHAR_ROW,
        DATA => CHAR_DATA
    );

    -- On the rising edge of 62ns clock, handle dot clock, vsync, hsync, and video signals
    video_data: process(CLK_62ns)
    begin
        if rising_edge(CLK_62ns) then
            CLK_DOT <= not CLK_DOT;
            if (Y < 20) then
                VSYNC <= '0';
            else
                VSYNC <= '1';
            end if;
            if (X < 256) then
                HSYNC <= '1';
            else
                HSYNC <= '0';
            end if;
            VIDEO <= CHAR_DATA(to_integer(7 - unsigned(X(2 downto 0))));
        end if;
    end process;

    -- On the falling edge of 62 ns clock, update internal video position
    video_pos: process(CLK_62ns)
    begin
        if falling_edge(CLK_62ns) then
            if (X >= 511) then
                X <= (others => '0');
                if (Y >= 259) then
                    Y <= (others => '0');
                    CHAR_ROW <= (others => '0');
                    VRAM_Row <= (others => '0');
                else
                    Y <= Y + 1;
                    if (CHAR_ROW = "1001") then
                        CHAR_ROW <= (others => '0');
                        VRAM_ROW <= VRAM_ROW + 1;
                    else
                        CHAR_ROW <= CHAR_ROW + 1;
                    end if;
                end if;
            else
                X <= X + 1;
            end if;
        end if;
    end process;

    -- Serial

    stdout: process (CLK_n)
    begin
        if rising_edge(CLK_n) then
            if (IORQ_n = '0') then
                if (RD_n = '0') then
                    report "IO READ " &
                        to_hstring(ADDR) &
                        " = " &
                        to_hstring(DATA) &
                        " '" &
                        to_string(character'val(to_integer(unsigned(DATA)))) &
                        "'";
                end if;
                if (WR_n = '0') then
                    report "IO WRITE " &
                        to_hstring(ADDR) &
                        " = " &
                        to_hstring(DATA) &
                        " '" &
                        to_string(character'val(to_integer(unsigned(DATA)))) &
                        "'";
                end if;
            end if;
        end if;
    end process;
end;
