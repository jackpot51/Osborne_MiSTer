library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use std.textio.all;

entity testbench is
end testbench;

architecture behavior of testbench is
    -- Z80 CPU
    signal RESET_n: std_logic := '0';
    signal clock_cpu: std_logic;
    signal ADDR: std_logic_vector(15 downto 0);
    signal DATA: std_logic_vector(7 downto 0);

    -- Clocks
    signal clock_62ns: std_logic := '0';
    signal clock_dot: std_logic;

    -- ROM
    signal boot_rom_read_n: std_logic;
    signal ROM_EN_n: std_logic := '0';
    signal ROM_HAS_ADDR_n: std_logic := '0';

    -- DIM

    signal dim_read_n: std_logic;
    signal dim_write_n: std_logic;

    -- RAM
    signal ram_read_n: std_logic;
    signal ram_write_n: std_logic;

    -- Keyboard
    signal keyboard: std_logic_vector(63 downto 0) := (others => '0');

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
    signal VIDEO_DIM: std_logic := '0';
begin
    RESET_n <= '1' after 500 ns;
    clock_62ns <= not clock_62ns after 62 ns;

    osborne_1: entity work.osborne_1 port map (
        -- Z80 CPU
        reset_n => RESET_n,
        clock_cpu => clock_cpu,
        address => ADDR,
        data => DATA,

        -- Clocks
        clock_62ns => clock_62ns,
        clock_dot => clock_dot,

        -- ROM
        boot_rom_read_n => boot_rom_read_n,

        -- DIM
        dim_read_n => dim_read_n,
        dim_write_n => dim_write_n,

        -- RAM
        ram_read_n => ram_read_n,
        ram_write_n => ram_write_n,
    
        -- Keyboard
        keyboard => keyboard
    );

    -- ROM (4KiB when ROM_EN_n is low)

    boot_rom: entity work.rom
    generic map (
        g_ADDR_WIDTH => 12,
        g_MEM_IMG_FILENAME => "build/boot_rom.txt"
    )
    port map (
        CLK_n => clock_cpu,
        RD_n => boot_rom_read_n,
        ADDR => ADDR(11 downto 0),
        DATA => DATA
    );

    -- RAM

    ram: entity work.ram
    generic map (
        g_ADDR_WIDTH => 16
    )
    port map (
        A_CLK_n => clock_cpu,
        A_RD_n => ram_read_n,
        A_WR_n => ram_write_n,
        A_ADDR => ADDR,
        A_DATA => DATA,
        --TODO: best clock to use?
        B_CLK_n => not clock_62ns,
        B_RD_n => '0',
        B_WR_n => '1',
        B_ADDR(6 downto 0) => std_logic_vector(X(9 downto 3)),
        B_ADDR(11 downto 7) => VRAM_ROW(4 downto 0),
        B_ADDR(15 downto 12) => "1111",
        B_DATA => VRAM_DATA
    );

    -- Dim attribute

    dim: entity work.ram
    generic map (
        g_ADDR_WIDTH => 12,
        g_DATA_WIDTH => 1
    )
    port map (
        A_CLK_n => clock_cpu,
        A_RD_n => dim_read_n,
        A_WR_n => dim_write_n,
        A_ADDR => ADDR(11 downto 0),
        A_DATA(0) => DATA(7),
        --TODO: best clock to use?
        B_CLK_n => not clock_62ns,
        B_RD_n => '0',
        B_WR_n => '1',
        B_ADDR(6 downto 0) => std_logic_vector(X(9 downto 3)),
        B_ADDR(11 downto 7) => VRAM_ROW(4 downto 0),
        B_DATA(0) => VIDEO_DIM
    );

    -- Video

    character_rom: entity work.rom_async
    generic map (
        g_ADDR_WIDTH => 11,
        g_MEM_IMG_FILENAME => "build/char_rom.txt"
    )
    port map (
        ADDR(6 downto 0) => VRAM_DATA(6 downto 0),
        ADDR(10 downto 7) => CHAR_ROW,
        DATA => CHAR_DATA
    );

    -- On the rising edge of 62ns clock, handle dot clock, vsync, hsync, and video signals
    video_data: process(clock_62ns)
    begin
        if rising_edge(clock_62ns) then
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
    video_pos: process(clock_62ns)
    begin
        if falling_edge(clock_62ns) then
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
end;
