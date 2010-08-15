8Track:

	Monome 64 application (http://monome.org) created by 
	Martin Alexander Hammer, martin.hammer at gmail.com

	Built on top of the Monomer Ruby library located at 
	http://github.com/samaaron/monomer/

Introduction:

	Version 0.1

	8Track is a Roland X0X-style MIDI step sequencer with 8 
	instruments / tracks. It is best suited for percussion, as the
	instruments are monophonic and send out a fixed MIDI note (works 
	well with software like Ableton Drum Racks or Native Instruments 
	Battery).

	Each instrument has 40 patterns available with individual lengths 
	for polyrythmic fun and a randomization function.

	You can change the currently playing pattern of an instrument without 
	changing the playing patterns of other instruments (think Ableton Live 
	session view).

	It is also possible to save all instrument patterns and load them again
	at a different time, a feature strangely absent from most other Monome 
	apps I have seen.
	
	At the moment I have only tested the application with a Monome 64 on
	Mac OS X 10.6.4
	
	Any feedback is very welcome!

Quick-start:

	1. Install jRuby (http://jruby.codehaus.org/) and include it in 
	   your environment path
	2. Create an IAC virtual MIDI bus
	3. Run './8track.rb my_fine_project.save' from a terminal
	4. Load your favorite software sampler

Interface:

	1st row: Instrument selection
	Push one of these steps to select an instrument. This will display the 
	patterns of the selected instrument on the next five rows.

	2nd to 6th row: Pattern selection
	These rows display the patterns of the currently selected instrument. 
	A lit LED indicates a pattern with steps entered while a flashing LED 
	indicates the currently selected pattern.

	When you select a pattern, it will begin to play (if the sequencer is 
	running), and you will be able to edit the steps.

	7th row: Pattern steps
	This row shows the actual steps in the selected pattern. A step can 
	have one of three states; off (LED off), on (LED on) and accented (LED 
	blinking).

	Each step's state is toggled by pushing it once. The "on" state sends 
	MIDI velocity 75, while an accented step sends a velocity of 100.

	Hold the first step button for a moment to randomize the pattern.

	8th row: Sequencer control and status
	The leftmost button starts and stops playback. If held for a moment, it
	will save the current patterns to disk (two flashes of all buttons 
	indicate the start and finish of the save operation).

	This row also shows the "running light" indicating the currently active
	step in a sequence.

	The default sequence length is the entire width of your Monome, but 
	hold one of the steps in this row to set the last step in a pattern
	(this does not affect the length of other patterns).

License:

	(The MIT License)

	Copyright (c) 2007 Tom Preston-Werner

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	'Software'), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
