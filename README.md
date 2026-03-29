# GB-Noise 👾

4 channel noise and visual synth for gameboy.

Writen in assembly for RGBDS

## Software details

4 voices
- select plus right and left change which audio channel -- ~~milestone 1~~ **DONE**
- Dpad up and down control volume -- ~~milestore 2~~ **DONE**
- Dpad left and right control pitch -- ~~milestore 3~~ **DONE**
- A and B button is special function -- milestone 4
- Different graphics to represent each channel and volume -- milestone 5
- graphical embelishments to represent special functions -- milestone 6

## Usage
Select + dpad Right-Left -> Change channel
Select + down -> Mute current channel

Channel 1
↕️ D-Pad Up-Down -> Volume Control
↔️ D-pad Right-Left -> Frequency
🅰️ A button -> Change Sweep
🅱️ B button -> 

Channel 2
↕️ D-Pad Up-Down -> Volume Control
↔️ D-pad Right-Left -> Frequency
🅰️ A button -> Change Sweep
🅱️ B button -> 

Channel 3
↔️ D-Pad Up-Down -> Volume Control (4 settings; 0%, 25%, 50%, 100%)
↔️ D-pad Right-Left -> Frequency
🅰️ A button -> Wave ram?
🅱️ B button -> 

Channel 4
↕️ D-Pad Up-Down -> Volume Control
↔️ D-pad Right-Left -> Frequency
🅰️ A button -> Change LFSR width (bit 3 of NR43)
🅱️ B button -> increment clock divider?

BUGS/Improvements
Increase BPM or get rid of bpm and rely on timer 
Changing channels will result in freq changes by accident

## Setting up

Make sure you have [RGBDS](https://github.com/rednex/rgbds), at least version 0.4.0, and GNU Make installed. Python 3 is required for the PB16 compressor bundled as a usage example, but that script is optional.

## Compiling

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`.
This should create a bunch of things, including the output in the `bin` directory.

Pass the `-s` flag to `make` if it spews too much input for your tastes.
Päss the `-j <N>` flag to `make` to build more things in parallel, replacing `<N>` with however many things you want to build in parallel; your number of (logical) CPU cores is often a good pick (so, `-j 8` for me), run the command `nproc` to obtain it.

If you get errors that you don't understand, try running `make clean`.
If that gives the same error, try deleting the `assets` directory.
If that still doesn't work, try deleting the `bin` and `obj` directories as well.
If that still doesn't work, feel free to ask for help.


### Libraries

- [Variable-width font engine](https://github.com/ISSOtm/gb-vwf)
- [Structs in RGBDS](https://github.com/ISSOtm/rgbds-structs)


