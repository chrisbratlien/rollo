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
    #puts @now
    generate
    
    @next.go(self)

  # Ahh! a cliff!  
  end

  def evolve_probs
    #defining the improv lambdas
        if @improvs_file and File.exists?(@improvs_file)
                eval(File.read(@improvs_file))
        end
  end    


  def generate
    if $send_midi_clock and @now == 0.0
      puts "Sending initial MIDI Start"
      #@midi.driver.reset
      @midi.driver.stop
      @midi.driver.start
    end
    (0..$syncs_per_measure-1).each do |sync|      
      # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
      if sync % $syncs_per_step == 0
        step = sync / $syncs_per_step          
        collect_for_this_step = []

        $pr_player_note_range.each do |note|
          @roll.keys.each do |name|
            chan = @roll[name][:channel]
            #collect_for_this_step[chan] = [] if !collect_for_this_step[chan]
            if rand < @roll[name][:probs][note][step]
              collect_for_this_step << [note,chan,0.25,100]
            end  
          end
        end
        collect_for_this_step.each do |x|
          n,c,d,v = x      
          puts "channel #{c} #{n},#{d},#{v}"
          @timer.at(@start + @now) { @midi.note_on(n,c,v) }
          @timer.at(@start + @now + d) {@midi.note_off(n,0) }
        end
      end
      @timer.at(@start + @now + $midi_sync_offset) { @midi.driver.clock }
      @now += $sync_dt
    end
  end
  
end

midi = MIDIator::Interface.new
midi.autodetect_driver

timer = MIDIator::Timer.new(60.0/12000)
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
    :now => 0.to_f, #current time offset from start
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