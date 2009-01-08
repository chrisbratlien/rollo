alias :L :lambda
require 'rubygems'
require 'midiator'
require 'rb-music-theory'

class PianoRoll

  attr_reader :next,  :root_note,:scale_name, :scale, :roll, :chord, :degree_picker
  attr_accessor :now
  
  def initialize(attributes = {})	
    #puts "FELLAS I'M READY TO GETUP AND DO #{self} THANG"
    %w{midi next timer start root_note measure scale_name degree chord_picker roll queue options_file improvs_file logging }.each do |attribute|
      eval("@#{attribute} = attributes[:#{attribute}]")
    end 
    
        if @options_file and File.exists?(@options_file)
        eval(File.read(@options_file))
        end
  end
  
  def go(old_pr)  #now is the offset from start... i.e. the current time position         
     if !old_pr
        @now = 0
    else
        @now = old_pr.now
    end
     old_pr = nil
     
     puts "TIMER QUEUE: #{@timer.queue.size}"
    #############@now = now # you've got an importand job to do, son
    #puts @now
    #I WONDER: what if i just send the whole friggin attributes as the argument?
    @next = PianoRoll.new(
        :next => nil,
        :midi => @midi,
        :timer => @timer,
        :start => @start,
        :measure => @measure + 1,
        #:now => @now,  #the problem here is that this value will be old by the time this "next" PianoRoll "go"es
        :root_note => @root_note,
        :scale_name => @scale_name,
        :scale => @scale,
        :degree => @degree_picker[@degree,@scale_name],
        :chord_picker => @chord_picker,
        :roll => {},
        :options_file => @options_file,
        :improvs_file => @improvs_file,                          
        :logging => @logging)


    
    if $send_midi_clock and @now == 0
      puts "Sending initial MIDI Start"
      @midi.driver.start
    end

#    @improv || evolve_probs 


    @live = L { |newnow| @next.go(self) }
    @kill_me = L {|you| 
        puts "I've seen...time to die!"
        you = nil }
    
    @gen = L do |t|
        evolve_probs 
           (0..$steps_per_measure-1).each do |step|
                collect_for_this_step = []
                $pr_player_note_range.each do |note|
                  @roll.keys.each do |improv|
                    if rand < @roll[improv][note][step]
                      collect_for_this_step << note
                    end  
                  end
                end
                #puts "#{measure}.#{step+1} #{collect_for_this_step.inspect.to_s}"
                # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
                if $send_midi_clock
                  #24.times {@midi.driver.message(0xF8)}  #requires 24 pulses per quarter-note
                  24.times {@midi.driver.clock}
                end
                @timer.at(t) { 
                        puts "#{@measure}.#{step+1} #{collect_for_this_step.inspect.to_s}"
                        @midi.play collect_for_this_step, 0.25                 
                }
                t  += $step_dt
            end
        #
        
        #sleep(1)
        @kill_me[self] 
        @live[t]
    end

        @gen[t = @now]  # get your hands off my time
        gets
        sleep(100)
        #@now += (4 * $measure_dt)
        #@next.go(@now)
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
    
    
    
rollo = PianoRoll.new(
    :next => nil,
    :midi => midi,
    :timer => timer,   #MIDIator::Interface
    :start => start,   #Time.now.to_f (above)
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

rollo.go(nil) #passing zero is optional here.