# NOISE BOY 👾

4 channel noise and visualizer for gameboy.

Writen in assembly for RGBDS

## Usage
Select -> Cycle to next channel

Start -> Mute current channel

### Channel 1

↕ D-Pad Up-Down -> Volume Control

↔ D-pad Right-Left -> Frequency

🅐 button -> Toggle sweeping (this will disable volume control when toggeled)

🅑 button -> Wave Duty Cycle

### Channel 2

↕ D-Pad Up-Down -> Volume Control

↔ D-pad Right-Left -> Frequency

🅐 button -> Cycle Panning

🅑 button -> Wave Duty Cycle

### Channel 3

↔ D-Pad Up-Down -> Volume Control

↔ D-pad Right-Left -> Frequency

🅐 button -> (GBC only?) Writes random sample to (essentially) random ram wave index

🅑 button -> Change frequency radomly

### Channel 4

↕ D-Pad Up-Down -> Volume Control

↔ D-pad Right-Left -> Frequency

🅐 button -> Toggle LFSR randomness width (repetivie vs random)

🅑 button -> Cycle clock divider


## Setting up

Make sure you have [RGBDS](https://github.com/rednex/rgbds), at least version 0.4.0, and GNU Make installed.

## Compiling

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`.
This should create a bunch of things, including the output in the `bin` directory.

Pass the `-s` flag to `make` if it spews too much input for your tastes.
Päss the `-j <N>` flag to `make` to build more things in parallel, replacing `<N>` with however many things you want to build in parallel; your number of (logical) CPU cores is often a good pick (so, `-j 8` for me), run the command `nproc` to obtain it.

If you get errors that you don't understand, try running `make clean`.
If that gives the same error, try deleting the `assets` directory.
If that still doesn't work, try deleting the `bin` and `obj` directories as well.
If that still doesn't work, feel free to ask for help.

## Download
Check releases for a rom download

