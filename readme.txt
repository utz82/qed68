********************************************************************************
QED68 v0.1
by utz 04'2016 * www.irrlichtproject.de
********************************************************************************


About
=====

QED68 is a music player for the Texas Instruments TI-92 Plus graphing 
calculator. It mixes four channels of PCM samples in realtime, and outputs them
on the calculator's link port. Sound is played at around 24 KHz, with a total of
24 volume levels. Sound can be overdriven to ~170%.

QED68 runs best on real hardware. Tiemu produces heavy stutter on my PC, while 
VTI (which runs nowhere near the actual CPU speed of a TI-92 Plus) will fail to 
produce any sound whatsoever.

In theory, QED68 should also run on TI-89 and V200, but this has not been tested
and might require some adjustments to the code.


Composing Music
===============

QED68 comes with an utility that will convert standard eXtended Modules (.xm) to
the player's native format. The following restrictions apply:

- The module must contain exactly 4 channels.
- The global BPM must be greater than 77, and Spd must be 8.
  Sound quality degrades with increasing BPM values.
- All samples must be 8-bit, 44100 Hz.
- Samples must use forward looping or no looping.
- Instrument settings and sample pitch offsets will be ignored.
- Volume/panning and all fx commands are ignored, except E5x (finetune) and Bxx
  (jump to order).
  
Beware that sample quality will decrease significantly in the conversion 
process. The converter also boosts sample volumes beyond the maximum QED68 will 
handle without overdrive. In order to avoid overdrive, keep sample volumes 
below 75%.

The amount of sample data you can use is limited by the calculator's RAM.
xm2qed68 downsamples to 11025 Hz, so you should still be able get away with an 
.xm sized around 300-400 Kb.


Converting and Compiling
========================

You must have GCC4TI/TIGCC and tprbuilder (or the TIGCC IDE) installed to 
compile your tunes. In order to create a TI-92 Plus executable from your .xm, 
do the following:

1. Rename your .xm to "music.xm".
2. Run the xm2qed68 utility without any arguments.
3. Compile qed68.tpr, either with "tprbuilder qed68.tpr" or with TIGCC IDE.
4. Load the resulting "digiplayer.9xz" and "digi1.9xy" on your calculator.

Provided you're on *nix, have GCC4TI set up, and your .xm is already named 
"music.xm", you can simply run compile.sh to take care of the conversion 
process.


Music Data Format
=================

QED68's music data consists of four sections.

The first section is a single word-length definition of the module's speed.
Only the lower byte is actually used, the high byte must be 0. The value is 
calculated as

speed = 255-(19760/bpm)

The second section contains the song sequence. It consists of one or more 
longword pointers to the song's subsections (aka patterns), and is terminated
by a 0-longword.

A mandatory label named "sloop" must be present somewhere in the sequence.
Hence, the simplest sequence possible would be

sloop
   dc.l pattern1
   dc.l 0
   
The third section contains one or more patterns (subsections) with the actual
note and instrument data.

Note data is organized in rows, with each row consisting of a control word, 
followed by 0-4 note frequency definitions and instrument pointers.

The control word signifies how many definitions will follow. This is 
evaluated as follows:

If bit 0 is reset, channel 4 note frequency and sample pointer will be updated.
If bit 1 is reset, channel 3 note frequency and sample pointer will be updated.
If bit 2 is reset, channel 2 note frequency and sample pointer will be updated.
If bit 3 is reset, channel 1 note frequency and sample pointer will be updated.

The control word is then followed accordingly by 0-4 frequency and sample
definitions. The order is inverse, ie. starting with channel 4 and ending with
channel 1. Frequencies are word-length, sample definitions are longwords. 

At the beginning of a pattern, all 4 channels must be reloaded (so the first
control word is always 0).

If the control word is 0xFFFF, it signals the end of the pattern, ie. each
pattern must end with "dc.w $FFFF".

So, a simple pattern could look like this:

pattern1
   dc.w $0      ;ctrl word, reload all channels
   dc.w $0      ;channel 4 frequency (0 = silence)
   dc.l smp0    ;ch4 sample pointer
   dc.w $0      ;ch3 frequency
   dc.l smp0    ;ch3 sample pointer
   dc.w $1000   ;ch2 frequency
   dc.l smp3    ;ch2 sample pointer
   dc.w $2ff2   ;ch1 frequency
   dc.l smp1    ;ch1 sample pointer
   dc.w $f      ;ctrl word, don't reload anything for the next row
   dc.w $ffff   ;end of pattern


The pattern data is followed by a mandatory "blank" sample definition, to be
done as follows

   even
samples
smp0
   dc.b 0,$ff
   dc.l smp0

This is followed by one or more regular sample definitions. The following
sections discusses the sample data layout in further detail.



Sample Format
=============

- Samples are defined as unsigned, headerless, raw PCM WAVs.

- All sample volumes must be multiples of 4 (so only 0xn0, 0xn4, 0xn8, 0xnC
  are legal). Levels are divided by 4 internally.
  
- Keep in mind that only the first 24 volume levels are rendered correctly, so
  combined volume of the samples in all 4 channels should not significantly 
  exceed this limit unless you want heavy metal overdrive. In no case should
  the combined volume exceed 252. So ideally, a given sample would use a 
  maximum volume level of 6*4 = 0x18.

- Samples must be terminated with 0xFF. This acts as a stop byte, so the player
  can determine the sample's end.

- The stop byte is followed by a longword loop pointer definition. Loop points
  can be defined anywhere in the sample data (that means you can even loop to
  another sample if you like). If no looping is required, point to the blank
  sample (smp0).
  
- All samples must have an even number of bytes (including the stop byte!).


Greetings
=========

Many thanks to

- 1ng for donating his TI-92 Plus to the good cause
- Lionel Debroux for his help and advice
- Lionel Debroux again, for his work with gcc4ti, TiLP, and TI Link Guide
- all the people who've been documenting the 68k hardware over the years.

