# APU
The APU, or audio processing unit, is responsible for generating and outputting (analog) sound. It is connected over UART (plugged into the FPGC4 I/O Wing on a few headers), which allows for easy hardware upgrades, in case I ever want to switch to a STM32 based MCU.

The APU in the FPGC4 is a seperate MCU with its own RAM and storage, just like the SNES uses a seperate SPC700 and DSP chip to generate audio, saving FPGA resources and hours of time creating a complex APU. In the case of the FPGC4, a more modern and capable ESP32 is used as a software synthesizer with an I2S DAC attached to it. It currently works as a MIDI synthesizer, where the FPGC4 sends MIDI signals (three bytes per event) over UART to the ESP32 at 115200 bps, which then generates and outputs the sound in real time (with maybe one or two ms of delay because of the I2S buffer). For the future, I plan to use different sounds for different MIDI channels, so I can have multiple sounds at the same time.

The software is a modification from my ESP32Synth (standalone) project. It is written using the Arduino platform. Eventually, I might be better off using a Teensy3.6/4.0 (because form factor) or some STM32 Cortex M7 (though those chips are HUGE), and make use of their DSP libraries to allow for floating point operations and more polyphony.

## Picture
This is a picture of the current APU module using an ESP32 and I2S DAC, which plugs into headers on the bottom of the PCB:
<br>
<img src="../images/apu.jpg" alt="apu" width="400"/>