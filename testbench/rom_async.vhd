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

entity rom_async is
    generic (
        g_ADDR_WIDTH : positive := 16; -- bit width of ROM address bus
        g_DATA_WIDTH : positive := 8; -- bit width of ROM data bus
        
        -- relative path of memory image file
        g_MEM_IMG_FILENAME : string := ""
    );
    port (
        ADDR : in  std_logic_vector(g_ADDR_WIDTH - 1 downto 0); -- address bus
        DATA : out std_logic_vector(g_DATA_WIDTH - 1 downto 0) -- output data bus
    );
end entity rom_async;


architecture rtl of rom_async is
    type t_MEM is array(0 to integer((2 ** g_ADDR_WIDTH) - 1)) of
        std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    
    impure function create_mem_img return t_MEM is -- returns memory image
        file v_file     : text; -- file pointer
        variable v_line : line; -- read line
        
        variable v_mem        : t_MEM; -- memory image
        variable v_bit_vector : bit_vector(g_DATA_WIDTH - 1 downto 0); -- auxiliary vector for read
    begin
        
        if (g_MEM_IMG_FILENAME'length = 0) then -- linear initialization
            for i in t_MEM'range loop
                v_mem(i) := std_logic_vector(to_unsigned(0, g_DATA_WIDTH)); -- [address]=0
            end loop;
            report "The memory has been linearly initialized.";
        else -- initialization from a file
            report "The memory is about being initialized from a file.";
            file_open(v_file, g_MEM_IMG_FILENAME, read_mode);
            
            for i in t_MEM'range loop
                readline(v_file, v_line);
                -- read function from std.textio package does not work with std_logic_vector
                read(v_line, v_bit_vector);
                v_mem(i) := to_stdlogicvector(v_bit_vector); -- cast to std_logic_vector
            end loop;
            
            file_close(v_file);
            report "The initialization from a file has been successful."; 
        end if;
        
        return v_mem;
    end function create_mem_img;

    constant c_MEM : t_MEM := create_mem_img; -- calling the memory initialization
begin
    DATA <= c_MEM(to_integer(unsigned(ADDR)));
end architecture rtl;