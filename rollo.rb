alias :L :lambda
require 'rubygems'
require 'midiator'
require 'rb-music-theory'

class PianoRoll

  attr_accessor :midi, :timer, :start, :measure, :degree, :chord_picker, :options_file, :root_note, :scale_name, :scale, :roll, :chord, :degree_picker
  attr_accessor :improvs_file, :logging, :chord_name
  attr_accessor :now, :next
  
  def initialize(attributes = {})	
    #puts "FELLAS I'M READY TO GETUP AND DO #{self} THANG"
    %w{midi next timer start root_note measure scale_name degree chord_picker roll queue options_file improvs_file logging now}.each do |attribute|
      eval("@#{attribute} = attributes[:#{attribute}]")
    end 
  end
  
  def go(old_pr)  #now is the offset from start... i.e. the current time position         
    @now = old_pr.now if old_pr
    if @options_file and File.exists?(@options_file)
     eval(File.read(@options_file))
    end
 
    while @timer.queue.size > 5
      #puts "waiting..."
      sleep(1)
    end
    
    #@kill_me = L {|you| 
    #    puts "I've seen...time to die!"
    #    you = nil }


    #puts "TIMER QUEUE: #{@timer.queue.size}"
    @next.midi = @midi
    @next.timer = @timer
    @next.next = self
    @next.start = @start
    @next.measure = @measure + 1
    @next.root_note = @root_note
    @next.scale_name = @scale_name
    @next.scale = @scale
    @next.degree = @degree_picker[@degree,@scale_name]  #could also use old_pr.scale_name
    @next.chord_picker = @chord_picker
    @next.roll = @roll
    @next.options_file = @options_file
    @next.improvs_file = @improvs_file
    @next.logging = @logging

    evolve_probs
    if $send_midi_clock and @now == 0
      puts "Sending initial MIDI Start"
      @midi.driver.start
    end
    
    (0..$steps_per_measure-1).each do |step|
      collect_for_this_step = {}
      $pr_player_note_range.each do |note|
        @roll.keys.each do |name|
          chan = @roll[name][:channel]
          collect_for_this_step[chan] = [] if !collect_for_this_step[chan]
          if rand < @roll[name][:probs][note][step]
            collect_for_this_step[chan] << note
          end  
        end
      end
      #puts "#{measure}.#{step+1} #{collect_for_this_step.inspect.to_s}"
      # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
      if $send_midi_clock
        #24.times {@midi.driver.message(0xF8)}  #requires 24 pulses per quarter-note
        24.times {@midi.driver.clock}
      end
      @timer.at(@start + @now) do
        collect_for_this_step.keys.each do |chan|      
          puts "channel #{chan} #{collect_for_this_step[chan].inspect.to_s}"
          @midi.play(collect_for_this_step[chan],0.25,chan,100)
        end
      end        
      #@timer.at(@start + @now) do 
      #  puts "#{collect_for_this_step.inspect.to_s}"     
      #  collect_for_this_step.each do |note|          
      #    @midi.driver.note_on(note,0,100)
      #  end
      #end
      #@timer.at(@start + @now + 0.5) do 
      #  collect_for_this_step.each do |note|          
      #    @midi.driver.note_off(note,0,100)
      #  end
      #end
      @now  += $step_dt
      #q << [collect_for_this_step,@now]
    end
    
    @next.go(self)

  # Ahh! a cliff!  
  end

  def evolve_probs
    #defining the improv lambdas
        if @improvs_file and File.exists?(@improvs_file)
                eval(File.read(@improvs_file))
        end
  end    
end

midi = MIDIator::Interface.new
midi.autodetect_driver

timer = MIDIator::Timer.new(60.0/120)
start = Time.now.to_f

#midi = MIDIator::Interface.new
#midi.use :dls_synth
#include MIDIator::Notes

generate_scale = L{|note,scale_name| note.send(scale_name)}

generate_chord = L{|scale,degree| 
  cn = scale.valid_chord_names_for_degree(degree).pick
  scale.degree(degree).send(cn) 
}
harmonized_root_chord_picker = L {|scale,degree,root_chord_name|
  chord = scale.harmonized_chord(degree,root_chord_name)
  [chord,'harmonized I ' + root_chord_name]
}  
  
degree_chord_picker = L {|scale,degree,root_chord_name| 
  chord_name = scale.valid_chord_names_for_degree(degree).pick
  if !chord_name
    chord,chord_name = harmonized_root_chord_picker[scale,degree,root_chord_name]
  else
    chord = scale.degree(degree).send(chord_name)
  end
  [chord,chord_name]
}

favorite_scales = L {["mixolydian_scale",  "major_scale", "lydian_scale","natural_minor_scale"].pick}
    #"dorian_scale", "harmonic_minor_scale",,"melodic_minor_scale","locrian_scale", "hangman_scale"
    
    
    
rollo1 = PianoRoll.new(
    :next => nil,
    :midi => midi,
    :timer => timer,   #MIDIator::Interface
    :start => start,   #Time.now.to_f (above)
    :now => 0, #current time offset from start, integer
    :measure => 1,
    :root_note => Note.new(rand(20) + 45),
    :scale_name => favorite_scales[],
    :degree => 1,
		:chord_picker => degree_chord_picker,
		#:chord_picker => harmonized_root_chord_picker,
		#:chord_picker => [degree_chord_picker,harmonized_root_chord_picker].pick,
    :roll => {},
    #:queue => [],
    :cloner => L{|pr| pr = pr.next},
    :options_file => 'options.rb',
    :improvs_file => 'improvs.rb',
    :logging => true)

rollo2 = PianoRoll.new(
    :next => rollo1,
    :midi => midi,
    :timer => rollo1.timer,   #MIDIator::Interface
    :start => rollo1.start,   #Time.now.to_f (above)
    :measure => nil,
    :root_note => Note.new(rand(20) + 45),
    :scale_name => favorite_scales[],
    :degree => 1,
		:chord_picker => degree_chord_picker,
		#:chord_picker => harmonized_root_chord_picker,
		#:chord_picker => [degree_chord_picker,harmonized_root_chord_picker].pick,
    :roll => {},
    #:queue => [],
    :cloner => L{|pr| pr = pr.next},
    :options_file => 'options.rb',
    :improvs_file => 'improvs.rb',
    :logging => true)

rollo1.next = rollo2  # how cute, a circle

rollo1.go(nil)