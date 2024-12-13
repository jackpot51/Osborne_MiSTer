-- From https://github.com/dominiksalvet/vhdl-collection/blob/master/rtl/rom.vhdl
--------------------------------------------------------------------------------
-- Copyright (C) 2016-2018 Dominik Salvet
-- SPDX-License-Identifier: MIT
--------------------------------------------------------------------------------
-- Compliant: IEEE Std 1076-1993
-- Target:    independent
--------------------------------------------------------------------------------
-- Description:
--     Generic implementation of a single port synchronous ROM memory with
--     initialization from a file or a linear initialization where memory
--     content is [address]=address.
--------------------------------------------------------------------------------
-- Notes:
--     1. Since there is a read enable signal, DATA output will be implemented
--        as a register.
--     2. The module can be implemented as a block memory, if the target
--        platform and used synthesizer support it.
--     3. If it is required to use a linear initialization, set the
--        g_MEM_IMG_FILENAME generic to "".
--     4. If the initialization from a file will be used, the file must contain
--        only ASCII "0" and "1" characters, each line's length must be equal to
--        set g_DATA_WIDTH and file must have 2**g_ADDR_WIDTH lines.
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity ram is
    generic (
        g_ADDR_WIDTH : positive := 16; -- bit width of RAM address bus
        g_DATA_WIDTH : positive := 8 -- bit width of RAM data bus
    );
    port (
        A_CLK_n : in std_logic; -- clock signal
        A_RD_n   : in  std_logic; -- read enable
        A_WR_n   : in  std_logic; -- write enable
        A_ADDR : in  std_logic_vector(g_ADDR_WIDTH - 1 downto 0); -- address bus
        A_DATA : inout std_logic_vector(g_DATA_WIDTH - 1 downto 0); -- output data bus
        B_CLK_n : in std_logic; -- clock signal
        B_RD_n   : in  std_logic; -- read enable
        B_WR_n   : in  std_logic; -- write enable
        B_ADDR : in  std_logic_vector(g_ADDR_WIDTH - 1 downto 0); -- address bus
        B_DATA : inout std_logic_vector(g_DATA_WIDTH - 1 downto 0) -- output data bus
    );
end entity;


architecture rtl of ram is
begin
    -- Description:
    --     Memory read/write mechanism description.
    mem_rw : process (A_CLK_n, B_CLK_n) is
        type t_MEM is array(0 to integer((2 ** g_ADDR_WIDTH) - 1)) of
            std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        variable MEM: t_MEM := (
            others => (others => '0')
        );
    begin
        if (rising_edge(A_CLK_n)) then
            if (A_RD_n = '0') then
                A_DATA <= MEM(to_integer(unsigned(A_ADDR)));
            else
                if (A_WR_n = '0') then
                    MEM(to_integer(unsigned(A_ADDR))) := A_DATA;
                else
                    A_DATA <= (others => 'Z');
                end if;
            end if;
        end if;
        if (rising_edge(B_CLK_n)) then
            if (B_RD_n = '0') then
                B_DATA <= MEM(to_integer(unsigned(B_ADDR)));
            else
                if (B_WR_n = '0') then
                    MEM(to_integer(unsigned(B_ADDR))) := B_DATA;
                else
                    B_DATA <= (others => 'Z');
                end if;
            end if;
        end if;
    end process;
end architecture;