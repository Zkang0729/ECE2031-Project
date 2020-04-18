LIBRARY IEEE;
LIBRARY WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
ENTITY SRAM IS
  PORT (
    CLOCK : IN STD_LOGIC;
    IO_WRITE : IN STD_LOGIC;
    SRAM_UPPER_ADDR : IN STD_LOGIC;
    SRAM_LOWER_ADDR : IN STD_LOGIC;
    SRAM_DATA : IN STD_LOGIC;
    SRAM_INC_DATA : IN STD_LOGIC;
    SRAM_ADDR_JPOS : IN STD_LOGIC;
    SRAM_ADDR_JNEG : IN STD_LOGIC;
    IO_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    SRAM_CE_N : OUT STD_LOGIC;
    SRAM_WE_N : OUT STD_LOGIC;
    SRAM_OE_N : OUT STD_LOGIC;
    SRAM_UB_N : OUT STD_LOGIC;
    SRAM_LB_N : OUT STD_LOGIC;
    SRAM_ADDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
  );
END SRAM;

ARCHITECTURE bdf_type OF SRAM IS
  TYPE STATE_TYPE IS (
    IDLE,
    READ_UPPER,
    WRITE_UPPER,
    READ_LOWER,
    WRITE_LOWER,
    SRAM_READ,
    SRAM_INC_READ,
    SRAM_WRITE,
    SRAM_INC_WRITE,
    IDLE_INC_DELAY,
    JUMP_POS,
    JUMP_NEG
  );
  SIGNAL PREV_STATE : STATE_TYPE;
  SIGNAL STATE : STATE_TYPE;
  SIGNAL SRAM_ADDR_ALTERA_SYNTHESIZED : STD_LOGIC_VECTOR(17 DOWNTO 0) := "000000000000000000";

BEGIN
  -- Standard SRAM Controls
  SRAM_ADDR <= SRAM_ADDR_ALTERA_SYNTHESIZED;
  SRAM_CE_N <= '0';
  SRAM_UB_N <= '0';
  SRAM_LB_N <= '0';
  
  PROCESS (CLOCK)
	VARIABLE STATE_CODE : STD_LOGIC_VECTOR(6 DOWNTO 0);
  BEGIN
    IF (RISING_EDGE(CLOCK)) THEN
		STATE_CODE := IO_WRITE & SRAM_UPPER_ADDR & SRAM_LOWER_ADDR & SRAM_DATA & SRAM_INC_DATA & SRAM_ADDR_JPOS & SRAM_ADDR_JNEG;
		CASE STATE_CODE IS
			WHEN "0100000" => STATE <= READ_UPPER;
			WHEN "1100000" => STATE <= WRITE_UPPER;
			WHEN "0010000" => STATE <= READ_LOWER;
			WHEN "1010000" => STATE <= WRITE_LOWER;
			WHEN "0001000" => STATE <= SRAM_READ;
			WHEN "0000100" => STATE <= SRAM_INC_READ;
			WHEN "1001000" => STATE <= SRAM_WRITE;
			WHEN "1000100" => STATE <= SRAM_INC_WRITE;
			WHEN "1000010" => STATE <= JUMP_POS;
			WHEN "1000001" => STATE <= JUMP_NEG;
			WHEN OTHERS => STATE <= IDLE;
		END CASE;
		
		IF (STATE = IDLE) THEN
			SRAM_OE_N <= '1';
			SRAM_WE_N <= '1';
			IO_DATA <= "ZZZZZZZZZZZZZZZZ";
		END IF;
  
		IF (PREV_STATE /= STATE) THEN
			CASE STATE IS
				WHEN READ_LOWER => IO_DATA <= SRAM_ADDR_ALTERA_SYNTHESIZED(15 DOWNTO 0);
				WHEN WRITE_LOWER => SRAM_ADDR_ALTERA_SYNTHESIZED(15 DOWNTO 0) <= IO_DATA(15 DOWNTO 0);
				WHEN READ_UPPER => IO_DATA <= "00000000000000" & SRAM_ADDR_ALTERA_SYNTHESIZED(17 DOWNTO 16);
				WHEN WRITE_UPPER => SRAM_ADDR_ALTERA_SYNTHESIZED(17 DOWNTO 16) <= IO_DATA(1 DOWNTO 0);
				WHEN SRAM_READ => SRAM_OE_N <= '0';
				WHEN SRAM_INC_READ => SRAM_OE_N <= '0';
				WHEN SRAM_WRITE => SRAM_WE_N <= '0';
				WHEN SRAM_INC_WRITE => SRAM_WE_N <= '0';
				WHEN JUMP_POS => SRAM_ADDR_ALTERA_SYNTHESIZED <= STD_LOGIC_VECTOR(UNSIGNED(SRAM_ADDR_ALTERA_SYNTHESIZED) + UNSIGNED(IO_DATA));
				WHEN JUMP_NEG => SRAM_ADDR_ALTERA_SYNTHESIZED <= STD_LOGIC_VECTOR(UNSIGNED(SRAM_ADDR_ALTERA_SYNTHESIZED) - UNSIGNED(IO_DATA));
				WHEN OTHERS =>
					SRAM_OE_N <= '1';
					SRAM_WE_N <= '1';
					IO_DATA <= "ZZZZZZZZZZZZZZZZ";
			END CASE;

			CASE PREV_STATE IS
				WHEN SRAM_INC_READ => STATE <= IDLE_INC_DELAY;
				WHEN SRAM_INC_WRITE => STATE <= IDLE_INC_DELAY;
				WHEN IDLE_INC_DELAY => SRAM_ADDR_ALTERA_SYNTHESIZED <= STD_LOGIC_VECTOR(UNSIGNED(SRAM_ADDR_ALTERA_SYNTHESIZED) + 1);
				WHEN OTHERS => NULL;
			END CASE;
		END IF;
    
		PREV_STATE <= STATE;
    END IF;
  END PROCESS;
END bdf_type;