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

        -- 4 Kbit DIM
        dim_read_n: out std_logic;
        dim_write_n: out std_logic;

        -- 64 KiB RAM
        ram_read_n: out std_logic;
        ram_write_n: out std_logic;

        -- Keyboard
        keyboard: in std_logic_vector(63 downto 0)
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
    signal rom_has_addr_n: std_logic;

    -- DIM
    signal dim_en_n: std_logic := '0';
    signal dim_has_addr_n: std_logic;

    -- RAM
    signal ram_has_addr_n: std_logic;

    -- MMIO
    signal mmio_has_addr_n: std_logic;
    signal mmio_read_n : std_logic;
    signal mmio_write_n : std_logic;
begin
    -- Z80 CPU
    z80a: entity work.T80a port map (
        reset_n => reset_n,
        R800_mode => '0',
        CLK_n => clock_div(1),
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

    -- DIM (4kbit when DIM_EN_n is low)
    dim_has_addr_n <= dim_en_n or (not A(15)) or (not A(14)) or (not A(13)) or (not A(12));
    dim_read_n <= mreq_n or rd_n or dim_has_addr_n;
    dim_write_n <= mreq_n or wr_n or dim_has_addr_n;

    -- RAM
    ram_has_addr_n <= (not rom_has_addr_n) or (not dim_has_addr_n) or (not mmio_has_addr_n);
    ram_read_n <= mreq_n or rd_n or ram_has_addr_n;
    ram_write_n <= mreq_n or wr_n or ram_has_addr_n;

    -- PIA for video
    -- TODO: video_pia: entity work.pia6821 port map (
        -- clk => clock_div(1),
        -- rst => 
    -- );
    
    -- MMIO
    mmio_has_addr_n <= rom_en_n or (not rom_has_addr_n) or A(15) or A(14);
    mmio_read_n <= mreq_n or rd_n or mmio_has_addr_n;
    mmio_write_n <= mreq_n or wr_n or mmio_has_addr_n;

    mmio: process (clock_div(1))
    begin
        if rising_edge(clock_div(1)) then
            -- Handle MMIO registers
            if (mmio_read_n = '0') then
                case(A) is
                    -- Keyboard
                    when x"2201" => data <= keyboard(7 downto 0);
                    when x"2202" => data <= keyboard(15 downto 8);
                    when x"2204" => data <= keyboard(23 downto 16);
                    when x"2208" => data <= keyboard(31 downto 24);
                    when x"2210" => data <= keyboard(39 downto 32);
                    when x"2220" => data <= keyboard(47 downto 40);
                    when x"2240" => data <= keyboard(55 downto 48);
                    when x"2280" => data <= keyboard(63 downto 56);
                    -- Video PIA
                    --TODO when x"2C00" => data <= video_pia_a_data;
                    --TODO when x"2C02" => data <= video_pia_b_data;
                    --TODO: what do undefined registers do?
                    when others => 
                        report "MMIO read to undefined register " & to_hstring(A);
                        data <= "00000000";
                end case;
            elsif (mmio_write_n = '0') then
                case(A) is
                    --TODO when x"2C00" => video_pia_a_data <= data;
                    --TODO when x"2C01" => video_pia_a_control <= data;
                    --TODO when x"2C02" => video_pia_b_data <= data;
                    --TODO when x"2C03" => video_pia_b_control <= data;
                    when others =>
                        report "MMIO write to undefined register " & to_hstring(A) & " = " & to_hstring(data);
                end case;
            else
                data <= "ZZZZZZZZ";
            end if;

            -- Handle banking
            if (IORQ_n = '0') then
                if (WR_n = '0') then
                    if (A(1 downto 0) = "00") then
                        -- Enable ROM
                        rom_en_n <= '0';
                    end if;
                    if (A(1 downto 0) = "01") then
                        -- Disable ROM
                        rom_en_n <= '1';
                    end if;
                    if (A(1 downto 0) = "10") then
                        -- Enable DIM
                        dim_en_n <= '0';
                    end if;
                    if (A(1 downto 0) = "11") then
                        -- Disable DIM
                        dim_en_n <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
end;
