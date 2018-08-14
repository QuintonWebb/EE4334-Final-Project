--------------------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------------------------------------------------------------------------------------------------------
ENTITY Final_Project IS
	GENERIC(fclk: INTEGER := 1_600_000);
	PORT(
		sw_0, key_2, key_3, clk: IN BIT;	--sw_0 switches the thermostat between cool/heat mode. 
													--key_2 and key_3 increase and decrease room temperature respectively.
													--Clk is the internal CLOCK_50 that is used to drive various parts of the code.
		ledr_7: OUT BIT;	--LED used to show if the heater or AC is on/off.
		ssd_0, ssd_1, ssd_2, ssd_3, ssd_4: OUT BIT_VECTOR(6 DOWNTO 0) --On-board seven segment displays.Displays temperature values and thermostat mode.
	);
END ENTITY;
--------------------------------------------------------------------------------------------------------------------------------------------------------
ARCHITECTURE thermostat of Final_Project IS
	SIGNAL master_key: BIT;	--Signal used to determine which button is being pressed.
	SIGNAL clock_shift: BIT;	--Used in the Slow Counter Clock process. Acts as a proxy rising edge for the slowed down clock.
	SHARED VARIABLE temp_1: INTEGER RANGE 0 TO 9 := 8;	--Controls the value displayed on HEX0.
	SHARED VARIABLE temp_2: INTEGER RANGE 0 TO 9 := 6;	--Controls the value displayed on HEX1. The temp values are declared as shared
																		-- variables that are only changed in the room_temp process, but is seen in the
																		--and unaltered in the on_off process to determine whether to turn on LED7.
BEGIN
	master_key <= key_2 AND key_3;	--key_2 and key_3 and ANDed together. They have logic high on the DE1-SoC board when not pressed; 
												--when one of the buttons are pressed master_key = '0' and the program will then check whether 
												--key_2 or key_3 is being pressed (equal to '0'.)
	
	----------Slow Counter Clock----------
	--Slows down the internal CLOCK_50 so that the user can see the value displayed on HEX0 and HEX1 changed. Without this process
	--Holding the button down will cause the code to cycle through numerical values too quickly. clock_shift is a variable used to
	--tell the fpga to check for a button press; it is only logic high when counter_2 = 5 and resets at the next instantiation.
	clock: PROCESS (clk)
		VARIABLE counter1: NATURAL RANGE 0 TO fclk := 0;
		VARIABLE counter2: NATURAL RANGE 0 TO 5 := 0;
	BEGIN
		IF (clk'EVENT AND clk='1') THEN
			counter1 := counter1 + 1;
			clock_shift <= '0';
			IF (counter1 = fclk) THEN
				counter1 := 0;
				counter2 := counter2 + 1;
				clock_shift <= '0';
				IF (counter2 = 5) THEN
					counter2 := 0;
					clock_shift <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS clock;
	
	----------Mode Selection----------
	--This process sets the thermostat into cool or heat mode depending on the state of the on-board slide switch SW[0]
	--When SW[0] = '0', "C" is displayed on HEX4 and the number 72 is displayed across HEX3 and HEX2. Likewise, when
	--SW[0] = '1', "H" is displayed on HEX4 and the number 64 is displayed instead.
	mode_select: PROCESS (sw_0)
	BEGIN
		CASE sw_0 IS
			WHEN '0' => ssd_4 <= "1000110"; ssd_3 <= "1111000"; ssd_2 <= "0100100";
			WHEN '1' => ssd_4 <= "0001001"; ssd_3 <= "0000010"; ssd_2 <= "0011001";
			WHEN OTHERS => ssd_4 <= "0000110"; ssd_3 <= "0000110"; ssd_2 <= "0000110";
		END CASE;
	END PROCESS mode_select;
	
	----------Room Temperature Setting----------
	--This process allows the user to set the room temperature manually by pressing or holding down the on board buttons
	--KEY[2] and KEY[3] (increase and decrease respectively.) The display has a lower and upper limit of 40 and 99 
	--respectively. For any situation in which temp_1 = 9 and temp_2 is any non-nine integer, temp+1 resets back to 0 and
	--temp_2 is incremented up by one. In the decreasing portion, whenever temp_1 = '0' and temp_2 is any non-four integer,
	--temp_1 is = 9 and temp_2 is incremented down by 1.
	room_temp: PROCESS (clk, master_key, key_2, key_3)
	BEGIN
		IF (clk'EVENT AND clk='1' AND clock_shift='1') THEN
			IF (master_key='0') THEN
				IF (key_2='0') THEN
					IF (temp_1=9 AND temp_2=9) THEN
							temp_1 := 9;
							temp_2 := 9;
					ELSIF (temp_1=9) THEN
						temp_1 := 0;
						temp_2 := temp_2 + 1;
					ELSE
						temp_1 := temp_1 + 1;
					END IF;
				ELSIF (key_3='0') THEN
					IF (temp_1=0 AND temp_2=4) THEN
						temp_1 := 0;
						temp_2 := 4;
					ELSIF (temp_1=0) THEN
						temp_1 := 9;
						temp_2 := temp_2 - 1;
					ELSE
						temp_1 := temp_1 - 1;
					END IF;
				END IF;
			END IF;
		END IF;
		
		--The case statements below use temp_1 and temp_2 to shift out the 6-bit strings to the seven segment displays that'll
		--the room temperature. The others case is never used and will display an E on the SSD's.
		CASE temp_1 IS
			WHEN 0 => ssd_0 <= "1000000";
			WHEN 1 => ssd_0 <= "1111001";
			WHEN 2 => ssd_0 <= "0100100";
			WHEN 3 => ssd_0 <= "0110000";
			WHEN 4 => ssd_0 <= "0011001";
			WHEN 5 => ssd_0 <= "0010010";
			WHEN 6 => ssd_0 <= "0000010";
			WHEN 7 => ssd_0 <= "1111000";
			WHEN 8 => ssd_0 <= "0000000";
			WHEN 9 => ssd_0 <= "0010000";
			WHEN OTHERS => ssd_0 <= "0000110";
		END CASE;
		
		CASE temp_2 IS
			WHEN 0 => ssd_1 <= "1000000";
			WHEN 1 => ssd_1 <= "1111001";
			WHEN 2 => ssd_1 <= "0100100";
			WHEN 3 => ssd_1 <= "0110000";
			WHEN 4 => ssd_1 <= "0011001";
			WHEN 5 => ssd_1 <= "0010010";
			WHEN 6 => ssd_1 <= "0000010";
			WHEN 7 => ssd_1 <= "1111000";
			WHEN 8 => ssd_1 <= "0000000";
			WHEN 9 => ssd_1 <= "0010000";
			WHEN OTHERS => ssd_1 <= "0000110";
		END CASE;
	END PROCESS room_temp;
	
	----------Heat/Cool On/Off Setting----------
	--This tells the user if the heater or cooler is on by setting a threshold value for heat mode and cool mode and turning on
	--LED7 when this value is passed. The thresholds are as such: >72 for cool mode and <64 for heat mode.
	on_off: PROCESS (sw_0)
	BEGIN
		IF (sw_0='0') THEN
			IF (temp_1 = 3 AND temp_2 = 6) THEN
				ledr_7 <= '0';
			END IF;
			IF (temp_1 = 3 AND temp_2 = 5) THEN
				ledr_7 <= '0';
			END IF;
			IF (temp_1 = 3 AND temp_2 = 4) THEN
				ledr_7 <= '0';
			END IF;
			IF (temp_1 > 2 AND temp_2 >= 7) THEN
				ledr_7 <= '1';
			END IF;
			IF (temp_1 <= 2 AND temp_2 <= 7) THEN
				ledr_7 <= '0';
			END IF;
		ELSIF (sw_0='1') THEN
			IF (temp_1 = 3 AND temp_2 = 6) THEN
				ledr_7 <='1';
			END IF;
			IF (temp_1 < 4 AND temp_2 <= 6) THEN
				ledr_7 <= '1';
			END IF;
			IF (temp_1 >= 4 AND temp_2 >= 6) THEN
				ledr_7 <= '0';
			END IF;
		ELSE
			null;
		END IF;
	END PROCESS on_off;
END ARCHITECTURE;
--------------------------------------------------------------------------------------------------------------------------------------------------------











