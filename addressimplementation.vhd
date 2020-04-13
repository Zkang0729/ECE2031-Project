LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;

ENTITY addressimplementation IS
  PORT (
    CLOCK : IN STD_LOGIC;
    RESETN : IN STD_LOGIC;
    IO_WRITE : IN STD_LOGIC;
    SET_UPPER : IN STD_LOGIC;
    SET_LOWER : IN STD_LOGIC;
    SRAM_DATA : IN STD_LOGIC;
    SRAM_INC_DATA : IN STD_LOGIC;
    IO_DATA : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    SRAM_CE_N : OUT STD_LOGIC;
    SRAM_WE_N : OUT STD_LOGIC;
    SRAM_OE_N : OUT STD_LOGIC;
    SRAM_UB_N : OUT STD_LOGIC;
    SRAM_LB_N : OUT STD_LOGIC;
    SRAM_ADDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
  );
END addressimplementation;

ARCHITECTURE bdf_type OF addressimplementation IS
  TYPE STATE_TYPE IS (
    IDLE,
    SRAM_READ0,
    SRAM_READ1,
    SRAM_WRITE0,
    SRAM_WRITE1
  );
  SIGNAL STATE : STATE_TYPE;
  SIGNAL SRAM_ADDR_ALTERA_SYNTHESIZED : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL UPPER_ENABLE : STD_LOGIC;
  SIGNAL LOWER_ENABLE : STD_LOGIC;
  SIGNAL WRITE_ENABLE : STD_LOGIC;
  SIGNAL READ_ENABLE : STD_LOGIC;

  UPPER_ENABLE <= SET_UPPER AND IO_WRITE;
  LOWER_ENABLE <= SET_LOWER AND IO_WRITE;
  WRITE_ENABLE <= SRAM_DATA OR SRAM_INC_DATA AND IO_WRITE;
  READ_ENABLE <= SRAM_DATA OR SRAM_INC_DATA AND (NOT IO_WRITE);
  SRAM_ADDR <= SRAM_ADDR_ALTERA_SYNTHESIZED;
  SRAM_CE_N <= '0';
  SRAM_UB_N <= '0';
  SRAM_LB_N <= '0';

  PROCESS (CLOCK, UPPER_ENABLE, LOWER_ENABLE, SRAM_DATA, RESETN)
  BEGIN
    IF (RISING_EDGE(LOWER_ENABLE)) THEN
      SRAM_ADDR_ALTERA_SYNTHESIZED(15..0) <= IO_DATA(15..0);
    END IF;
    IF (RISING_EDGE(UPPER_ENABLE)) THEN
      SRAM_ADDR_ALTERA_SYNTHESIZED(17..16) <= IO_DATA(1..0);
    END IF;
    IF (RESETN = '0') THEN
      STATE <= IDLE;
    ELSE
      IF (RISING_EDGE(CLOCK AND READ_ENABLE)) THEN
        STATE <= SRAM_READ0;
      END IF;
      IF (RISING_EDGE(CLOCK AND WRITE_ENABLE)) THEN
        STATE <= SRAM_WRITE0;
      END IF;
    END IF;
    CASE STATE IS
      WHEN IDLE =>
        SRAM_WE_N <= '1';
        SRAM_OE_N <= '1';

      WHEN SRAM_READ0 =>
        SRAM_OE_N <= '0';
        IF (SRAM_INC_DATA = '1')
          STATE <= SRAM_READ1;
        END IF;

      WHEN SRAM_WRITE0 =>
        SRAM_WE_N <= '0';
        IF (SRAM_INC_DATA = '1')
          STATE <= SRAM_WRITE1;
        END IF;

      WHEN SRAM_READ1 =>
        SRAM_ADDR_ALTERA_SYNTHESIZED = SRAM_ADDR_ALTERA_SYNTHESIZED + '1';

      WHEN SRAM_WRITE1 =>
        SRAM_ADDR_ALTERA_SYNTHESIZED = SRAM_ADDR_ALTERA_SYNTHESIZED + '1';
    END CASE;
  END PROCESS;
END bdf_type;