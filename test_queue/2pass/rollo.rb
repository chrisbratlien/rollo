alias :L :lambda
require 'rubygems'
require 'midiator'
require 'rb-music-theory'

class PianoRoll

  attr_accessor :midi, :on_timer, :off_timer, :start, :measure, :degree, :chord_picker, :options_file, :root_note, :scale_name, :scale, :roll, :chord, :degree_picker
  attr_accessor :improvs_file, :logging, :chord_name
  attr_accessor :now, :next, :song_queue
  
  def initialize(attributes = {})	
    #puts "FELLAS I'M READY TO GETUP AND DO #{self} THANG"
    %w{midi next on_timer off_timer start root_note measure scale_name degree chord_picker roll queue options_file improvs_file logging now}.each do |attribute|
      eval("@#{attribute} = attributes[:#{attribute}]")
    @song_queue = []
    end
  end
  
  def go(old_pr)  #now is the offset from start... i.e. the current time position         
    @now = old_pr.now if old_pr
    
    @test = Time.now.to_f
    #@now = @test if @now < @test  #if you're behind, catch up to real now
  
    puts "measure is #{@measure}"
    if @options_file and File.exists?(@options_file)
     eval(File.read(@options_file))
    end

    puts "going.. on measure #{@measure}"
    #while @on_timer.queue.size > 5
    #  #puts "waiting..."
    #  sleep(1)
    #end
    

    #puts "TIMER QUEUE: #{@timer.queue.size}"
    @next.midi = @midi
    @next.song_queue = @song_queue
    @next.on_timer = @on_timer
    @next.off_timer = @off_timer
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
    #puts @now
    ##generate(self)
 
    generate = L do 
      evolve_probs
      
      [1,2,4,8].pick-1.times do
        
        queue = []
        (0..$steps_per_measure-1).each do |step|
          queue[step] = []
          $pr_player_note_range.each do |note|
            @roll.keys.each do |name|
              chan = @roll[name][:channel]
              #collect_for_this_step[chan] = [] if !collect_for_this_step[chan]
              if @num_gen[] < @roll[name][:probs][note][step]
                queue[step] << [note,chan,0.50,100]
              end  
            end
          end
        end
        
        @song_queue << queue
      end
      
      #regen = L {c[c,@now]}
      #@timer.at(@start + @now + $measure_dt) {@next.go(self)}
    end
    generate[]

    if @measure == 20
      play
    else
      @next.go(self)
    end
  # Ahh! a cliff!  
  end

  def evolve_probs
    #defining the improv lambdas
        if @improvs_file and File.exists?(@improvs_file)
                eval(File.read(@improvs_file))
        end
  end    


  def play
    @now = Time.now.to_f
    @start = 0.0

      if $send_midi_clock and @now == 0.0
        puts "Sending initial MIDI Start"
        #@midi.driver.reset
        @midi.driver.message(0xFA)
        #@midi.driver.start
      end
      
    @song_queue.each do |queue|
      #puts queue.inspect.to_s
      (0..$syncs_per_measure-1).each do |sync|      
        # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
        if sync % $syncs_per_step == 0
          step = sync / $syncs_per_step  
              puts queue[step].inspect.to_s
         queue[step].each do |x|
            n,c,d,v = x      
            #puts "channel #{c} #{n},#{d},#{v}"
            @on_timer.at(@start + @now) { @midi.note_on(n,c,v) }

            @off_timer.at(@start + @now + d) {@midi.note_off(n,0) }
          end
        end
        @on_timer.at(@start + @now + $midi_sync_offset) { @midi.driver.message(0xF8) }
        @now += $sync_dt
      end
    end
    sleep(10000)
  end
  
end

midi = MIDIator::Interface.new
midi.autodetect_driver

on_timer = MIDIator::Timer.new(0.0147)
off_timer = MIDIator::Timer.new(0.0147)
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
    :on_timer => on_timer,   #MIDIator::Interface
    :off_timer => off_timer,
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
    :on_timer => rollo1.on_timer,   #MIDIator::Interface
    :off_timer => rollo1.off_timer,   #MIDIator::Interface
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