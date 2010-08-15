#!/usr/bin/env jruby -wKU

LIB_DIR = File.dirname(__FILE__) + "/lib/"

require LIB_DIR + 'instrument'
require LIB_DIR + 'pattern'
require LIB_DIR + 'step'
require LIB_DIR + 'monomer/lib/monomer'
require 'yaml'

class EightTrack < Monomer::Listener

  before_start do

    # Init various parameters used elsewhere
    
    @cycle_count = 0
    @sequencer_running = false
    @blink_on = true
    @current_instrument = 0
    @current_pattern = 0
    @instruments = []
    @push_times = {}    
    @midi = Monomer::MidiOut.new
    
    # Y-axis positions of the UI elements
    
    @instrument_selector_start = 0
    @pattern_selector_start = 1
    @pattern_steps_start = 6
    @sequencer_control_start = 7
    
    # MIDI velocity for pattern steps
    
    @half_velocity = 50
    @full_velocity = 100
    
    @save_file = ARGV[0]
    
    if @save_file == nil
      puts "Usage: #{__FILE__} <save file>, e.x.: #{__FILE__} my_project.save"
      exit
    end
    
    File::exists?(@save_file) ? @loaded_instruments = self.load_project(@save_file) : @loaded_instruments = nil
  end

  on_start do     
    timely_repeat :bpm => 126, :prepare => L{main_loop}, :on_tick => L{@midi.play_prepared_notes!}
  end
  
  on_button_press do |x,y|
    
    # Nothing really happens until you release the button, because we need to determine if it was a long or short push. See on_button_release()
    # This just registers when the button was pressed.
    
    @push_times[x] = { y => Time.now }
  end

  on_button_release do |x,y|
    
    # Determine how long the button was held by looking at the time registered in the on_button_press() function 
    
    (Time.now - @push_times[x][y]) > 0.75 ? long_push = true : long_push = false

    # Figure out what to to based on the coordinates of the button pressed and how long it was held.
    # Each sequencer function is placed on different rows (the Y axis) which makes it easy to map a button push to a function.
    
    if y == @sequencer_control_start  
      
      # Start / stop, pattern length, control and "running" sequencer light
      
      if x == 0 
        long_push == false ? self.toggle_sequencer : self.save_project
      elsif long_push
        @instruments[@current_instrument].current_pattern.last_step = x
      end
      
    elsif y == @pattern_steps_start 
      
      # Individual pattern steps
      
      if x == 0 and long_push
        
        # First button is held - randomize the pattern
        
        @instruments[@current_instrument].current_pattern.randomize!
      else
        
        # Regular push - toggle the selected step
        
        @instruments[@current_instrument].current_pattern.steps[x].toggle if x <= (@instruments[@current_instrument].patterns[@current_pattern].steps.length-1)
      end
    
    elsif y >= @pattern_selector_start and y <= monome.num_rows-2 
      
      # Pattern selection
      
      @instruments[@current_instrument].change_pattern(coord_to_pattern(x,y), @instruments[@current_instrument].current_pattern.current_step) if x <= (@instruments[@current_instrument].patterns.length-1)
      
    elsif y == @instrument_selector_start 
      
      # Instrument selection
      
      self.change_instrument(x, long_push)
    end
  end

  def self.coord_to_pattern(x,y)
    
    # Figure out which pattern was selected:
    # y * number of rows, subtract x number of columns and you have the pattern number
    
    y = y - @pattern_selector_start
    ((y+1) * monome.num_rows)-(monome.num_cols-x) 
  end

  def self.change_instrument(x, long_push)
    
    # Long_push is not actually used for anything here right now
    
    @current_instrument = x
  end

  def self.toggle_sequencer
    
    # Start the sequencer if it is stopped, stop it if it is running
    
    case @sequencer_running
    when false:
      @sequencer_running = true
    else
      @sequencer_running = false
      
      # Reset all patterns to step 0
      
      instrument_count = 0
      @instruments.length.times do
        @instruments[instrument_count].reset_pattern_positions!
        instrument_count += 1
      end
    end
  end

  def self.main_loop
    
    begin
      
      # This is where the real sequencer is
      # The main_loop function is ran once each tick of Monomer timer
      
      trap("INT") { 
        
        # CTRL-C is pushed, exit
        
        puts "Shutting down..."
        monome.clear
        monome.led_off(0,monome.num_rows-1) # A stray LED fails to clear, so turn it off manually
        exit 
      }    
      
      case @cycle_count
      when 0:
        
        # Skip first cycle to get correct Monome size - bug in Monomer?
        # The Monomer lib is initialized with the size of a Monome 128, so to be able to calculate the correct
        # coordinates for other size Monomes we have to wait until Monomer figures out the correct Monome type attached (after the first cycle of the timer)
        
      when 1: 
        
        # Now we have the correct size of the connected Monome - initialize empty patterns for each instrument
        # If a save file was specified on the command line, we load the data from that instead.
        
        instrument_count = 0
        (monome.num_rows).times do
          @loaded_instruments == nil ? @instruments[instrument_count] = Instrument.new(monome.num_cols*((monome.num_rows-2)-1), monome.num_cols) : @instruments[instrument_count] = @loaded_instruments[instrument_count]
          @instruments[instrument_count].reset_pattern_positions!
          instrument_count += 1
        end
      else
        
        # Every other cycle than the two first runs like this:
        
        instrument_count = 0
        @instruments.length.times do
          
          # We loop through all instruments and:
          # Find any notes to be played. Found notes are "prepared" withe the prepare_note() function to be played at the end of this cycle.
          
          self.prepare_note(instrument_count, @instruments[instrument_count].current_pattern.steps[@instruments[instrument_count].current_pattern.current_step]) if @instruments[instrument_count].current_pattern.steps[@instruments[instrument_count].current_pattern.current_step].on? and @sequencer_running
          
          # Display the step position of the currently selected pattern (a.k.a. the "running light")
          
          self.display_pattern_position(@instruments[instrument_count].current_pattern.steps, @instruments[instrument_count].current_pattern.current_step) if instrument_count == @current_instrument

          # Display steps in the currently selected pattern
          
          self.display_pattern_steps(@instruments[instrument_count].current_pattern.steps) if instrument_count == @current_instrument

          # Display the pattern selector (currently selected pattern flashes, patterns with steps are lit up)
          
          self.display_patterns(@instruments[instrument_count].patterns) if instrument_count == @current_instrument

          # Advance all steps in all currently playing patterns
          
          @instruments[instrument_count].current_pattern.advance_step if @sequencer_running
          
          instrument_count += 1
        end
        
        # Display the instrument selector (currently selected instrument button is lit up)
        
        self.display_instrument_selector
        
        # Display the running status of the sequencer (blinking if running)
        
        self.display_sequencer_blinker(@instruments[@current_instrument].patterns[@current_pattern].current_step)
        
        # All blinking LEDs blink in unison by following the global "blink state". The blink state changes between on and off at every tick.
        
        self.toggle_blink
      end
    
    @cycle_count += 1
    
    rescue Exception=>e
      puts "Error: #{e.message}"
      puts e.backtrace.first
    end
  end

  def self.display_sequencer_blinker(current_step)
    if current_step != 0
      if @sequencer_running and @blink_on == true
        monome.led_on(0,@sequencer_control_start)
      else
        monome.led_off(0,@sequencer_control_start) 
      end
    end
  end

  def self.display_instrument_selector
    
    x = 0
    y = @instrument_selector_start
    
    step_count = 0
    @instruments.length.times do
      
      x = step_count
      
      if step_count == @current_instrument
        monome.led_on(x, y)
      else
        monome.led_off(x, y)
      end
      step_count += 1
    end
  end

  def self.display_pattern_position(steps, current_step)
    
    y = @sequencer_control_start
    step_count = 0
    steps.length.times do
      
      x = step_count
      
      if step_count == current_step
        monome.led_on(x, y)
      else
        monome.led_off(x, y)
      end
      step_count += 1
    end  
  end

  def self.display_pattern_steps(steps)

    x = 0
    y = @pattern_steps_start
    step_count = 0
    
    steps.length.times do
      
      x = step_count
            
      case steps[step_count].on?
      when true
        case steps[step_count].velocity?
        when true
          case @blink_on
          when true:
            monome.led_on(x, y)
          else
            monome.led_off(x, y)
          end
        else
          monome.led_on(x, y)
        end
      else
        monome.led_off(x, y)
      end
      
      step_count += 1
    end
  end

  def self.display_patterns(patterns)
    
    pattern_count = 0
    
    patterns.length.times do
      y = (pattern_count/monome.num_rows) + @pattern_selector_start
      x = (pattern_count%monome.num_rows)

      if @instruments[@current_instrument].current_pattern_num == self.coord_to_pattern(x,y)
        @blink_on == true ? monome.led_on(x,y) : monome.led_off(x,y)
      else
        if !patterns[pattern_count].empty?
          monome.led_on(x, y)
        else
          monome.led_off(x,y)
        end
      end
      pattern_count += 1
    end
  end
  
  def self.toggle_blink
    @blink_on ? @blink_on = false : @blink_on = true
  end

  def self.save_project
    
    # Dump everything in YAML format
    # Spawn a new thread so we don't disturb the sequencer
    
    Thread.new {
      puts "Saving '#{@save_file}...'"
      monome.all and sleep 0.3
      monome.clear
      begin
        File.open(@save_file, 'w') do |out|
          YAML::dump(@instruments, out)
        end
        puts "Saving complete"
      rescue Exception => e
        puts "Error: #{e.message}"
        puts e.backtrace.first
      end
      monome.all and sleep 0.3
      monome.clear
    }
  
  end
  
  def self.load_project(save_file)
    loaded_instruments = nil
    puts "Loading '#{save_file}...'"
    begin
      loaded_instruments = YAML::load_file(@save_file)
      puts "#{loaded_instruments.length} instruments loaded"
    rescue Exception => e
      puts "Error: #{e.message}"
      puts e.backtrace.first
    end
    loaded_instruments
  end

  def self.prepare_note(instrument_num, step)
    
    # Notes start at C-1 and increase with each instrument number
    
    note = 36 + instrument_num
    step.velocity? ? velocity = @full_velocity : velocity = @half_velocity
    
    # Vary the velocity a little to make it more interesting :)
    
    ((velocity+rand(10))%2) == 0 ? velocity += rand(10) : velocity -= rand(10)
    @midi.prepare_note(:channel => 1, :duration => 0.2 * (60 / 120.0 / 4), :note => note, :velocity => velocity)
  end
end

Monomer::Monome.create.with_listeners(EightTrack).start if $0 == __FILE__