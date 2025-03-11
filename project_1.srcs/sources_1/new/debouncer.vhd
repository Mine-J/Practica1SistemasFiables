--------------------------------------------------------------------------------
--
-- Title       : 	Debounce Logic module
-- Design      :	
-- Author      :	Pablo Sarabia Ortiz
-- Company     :	Universidad de Nebrija
--------------------------------------------------------------------------------
-- File        : debouncer.vhd
-- Generated   : 7 February 2022
--------------------------------------------------------------------------------
-- Description : Given a synchronous signal it debounces it.
--------------------------------------------------------------------------------
-- Revision History :
-- -----------------------------------------------------------------------------

--   Ver  :| Author            :| Mod. Date :|    Changes Made:

--   v1.0  | Pablo Sarabia     :| 07/02/22  :| First version

-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity debouncer is
    generic(
        g_timeout          : integer   := 5;        -- Time in ms
        g_clock_freq_KHZ   : integer   := 100_000   -- Frequency in KHz of the system 
    );   
    port (  
        rst_n       : in    std_logic; -- asynchronous reset, low -active
        clk         : in    std_logic; -- system clk
        ena         : in    std_logic; -- enable must be on 1 to work (kind of synchronous reset)
        sig_in      : in    std_logic; -- signal to debounce
        debounced   : out   std_logic  -- 1 pulse flag output when the timeout has occurred
    ); 
end debouncer;


architecture Behavioural of debouncer is 
      
    -- Calculate the number of cycles of the counter (debounce_time * freq), result in cycles
    constant c_cycles           : integer := integer(g_timeout * g_clock_freq_KHZ) ;
	-- Calculate the length of the counter so the count fits
    constant c_counter_width    : integer := integer(ceil(log2(real(c_cycles))));
    
    -- -----------------------------------------------------------------------------
    -- Declarar un tipo para los estados de la fsm usando type
    -- -----------------------------------------------------------------------------
    type state_type is (s0,s1,s2,s3);
	signal current_state, next_state : state_type := s0;
	signal counter : integer range 0 to c_cycles := 0;
    signal time_elapsed : std_logic := '0';
    
begin
    --Timer
    process (clk, rst_n)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                current_state <= s0;
                counter <= 0;  -- Inicialización aquí
                time_elapsed <= '0';
            else
                current_state <= next_state;
                if current_state = s1 or current_state = s3 then
                    if counter = c_cycles then
                        time_elapsed <= '1';
                    else
                        counter <= counter + 1;
                    end if;
                else
                    counter <= 0;
                    time_elapsed <= '0';
                end if;
            end if;
        end if;
    end process;

    --FSM Register of next state
    process (clk, rst_n)
    begin
        case current_state is
            when s0 => 
                debounced <= '0';
                if sig_in = '1' then
                    next_state <= s1;
                else 
                    next_state <= s0;
                end if;
            when s1 =>
                debounced <= '0';
                if ena = '0' or (time_elapsed = '1' and sig_in = '0') then 
                    next_state <= s0;
                elsif (sig_in = '1') and (time_elapsed = '1') then
                    -- Aquí eliminamos la reasignación de counter
                    next_state <= s2;
                elsif time_elapsed = '0' then
                    next_state <= s1;
                end if;
            when s2 => 
                debounced <= '1';
                if ena = '0' then 
                    next_state <= s0;
                elsif sig_in = '0' then
                    next_state <= s3;
                else
                    next_state <= s2;
                end if;
            when s3 => 
                debounced <= '0';
                if sig_in = '0' then 
                    next_state <= s3;
                elsif ena = '0' or (time_elapsed = '1') then
                    
                    next_state <= s0;
                end if;
        end case;
    end process;
	
end Behavioural;