alias :L :lambda
require 'rubygems'
require 'rb-music-theory'
require 'lib/midi/live_midi'
require 'lib/midi/clock'
require 'lib/midi/note'

class PianoRoll

  attr_accessor :midi, :timer, :start, :measure, :degree, :chord_picker, :options_file, :options_ruby
  attr_accessor :improvs_file, :logging, :chord_name, :improvs_ruby,  :root_note, :scale_name, :scale
  attr_accessor :now, :next,  :roll, :chord, :next_chord, :degree_picker
  
  def initialize(attributes = {})	
    %w{midi next timer start root_note measure scale_name degree chord_picker roll queue options_file improvs_file logging now}.each do |attribute|
      eval("@#{attribute} = attributes[:#{attribute}]")
    @improvs_ruby = "true"
    @options_ruby = "true"
    end 
  end


  def evolve_probs
    #defining the improv lambdas
        if (@measure-1) % 2 == 0 and @improvs_file and File.exists?(@improvs_file)
          @improvs_ruby = File.read(@improvs_file)
        end
        eval(@improvs_ruby)
  end    
  
  def go    

    generate_beats = L do
      if (@measure-1) % 2 == 0 and @options_file and File.exists?(@options_file)
        @options_ruby = File.read(@options_file)     
      end
      eval(@options_ruby)

      #puts @midi.timer.queue.size
      #while @midi.timer.queue.size > 5
      #  puts "waiting...#{@midi.timer.queue.size}"
      #  sleep(1)
      #end

      evolve_probs

      if $send_midi_clock and $clock.time == 0.0
        puts "Sending initial MIDI Start"
        @midi.sync_stop
        @midi.sync_start
      end

      (0..$clock.syncs_per_measure-1).each do |sync|      
        # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
        if sync % $clock.syncs_per_step == 0
          step = sync / $clock.syncs_per_step          
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
            #puts "channel #{c} #{n},#{d},#{v}"
            @midi.play(Archaeopteryx::Midi::Note.new(c,n,d,v))
            #@timer.at(@start + @now) { @midi.note_on(n,c,v) }
            #@timer.at(@start + @now + d) {@midi.note_off(n,0) }
          end
        end
        @midi.sync_clock($clock.time + $clock.interval)
        $clock.sync_tick
      end
      @measure += 1
      @degree,@chord,@chord_name = @next_degree,@next_chord,@next_chord_name
      @roll = {}
      @midi.timer.at(($clock.start + $clock.time), &generate_beats)
    end
    generate_beats[]
    
    if Platform::IMPL == :mswin
      puts 'Press CTRL-C to stop'
      sleep(10000)
    else
      gets
    end
  end
end


$clock = Archaeopteryx::Midi::Clock.new(80)
#$mutation = L{|measure| 0 == (measure - 1) % 2}
$measures = 4 # not sure I nead this


midi = Archaeopteryx::Midi::LiveMIDI.new(
  :clock => $clock,
  :measures => $measures,
  :logging => true
  )

#timer = MIDIator::Timer.new(60.0/12000)
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
    
    
    
rollo = PianoRoll.new(
    :next => nil,
    :midi => midi,
    #:timer => timer,   #MIDIator::Interface
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

rollo.go