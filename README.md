# EE4334-Final-Project
Contains VHDL code that I used in the final project of my programmable logic class; it simulates a thermostat. The project was rather simple and I plan to create my own Type I testbench for it. The code was simulated on the terasIC DE1-SoC Development Kit with Quartus Prime Lite Edition. The files only include the .vhd and .sdc files; the .bdf and symbol files will have to be made on your own.

On boot-up, HEX1 and HEX0 (2 onboard seven segment displays) will display 6 and 8 respectively (68 is the starting room temperature.) We can change this room temperature by clicking either KEY2 or KEY3 which will increment the room temperature upwards and downwards respectively. The De1-SoC doesn't have a built in temperature sensor and I was not provided with one in class, so the room temperature was simulated through this method.

The slide switch SW0 is used to determine whether the thermostat is on heat or cool mode; at logic low, the system is in cool mode and in logic high, the system is in heat mode. This switch also controls what is displayed on the 3 SSD's HEX2, HEX3, and HEX4. When SW0 is logic low, HEX4 will display a "C" and HEX3 and HEX2 will display the number 72; when SW0 is logic high, HEX4 will display "H" and the other 2 SSD's will display the number 64. these number values act as thresholds that will be explained next

LEDR7 is used to show that the heater or cooler is on. When in heat mode, if the room temperature falls below 64 degrees, the LED will turn on to show that the heater is on; likewise, if the cool mode is activated and temperature rises above 72 degrees, the LED will turn on to indicate that the cooler is on.
