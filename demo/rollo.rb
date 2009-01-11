alias :L :lambda
require 'rubygems'
require 'midiator'
require 'rb-music-theory'

class PianoRoll

  attr_reader :next, :root_note,:scale_name, :scale, :roll, :chord, :degree_picker
  
  def initialize(attributes = {})	
    #puts "FELLAS I'M READY TO GETUP AND DO #{self} THANG"
    %w{midi next root_note scale_name degree chord_picker roll queue options_file improvs_file logging}.each do |attribute|
      eval("@#{attribute} = attributes[:#{attribute}]")
    end 
    if @options_file and File.exists?(@options_file)
      eval(File.read(@options_file))
    end
    puts "#{@root_note.name} #{@scale_name}, degree #{@degree},  #{@chord_name}"
  end
  
  def go         
    @next = PianoRoll.new(:midi => @midi,
                          :next => nil,
                          :root_note => @root_note,
                          :scale_name => @scale_name,
                          :scale => @scale,
                          :degree => @degree_picker[@degree,@scale_name],
                          :chord_picker => @chord_picker,
                          :roll => {},
                          :options_file => @options_file,
                          :improvs_file => @improvs_file,                          
                          :logging => @logging)

    evolve_probs
      
    (1..4).each do |measure|
      #puts "\a" if measure == 1
      (0..3).each do |step|
        collect_for_this_step = []
        $pr_player_note_range.each do |note|
          @roll.keys.each do |improv|
            if rand < @roll[improv][note][step]
              collect_for_this_step << note
            end  
          end
        end
        puts "#{measure}.#{step+1} #{collect_for_this_step.inspect.to_s}"
        @midi.play collect_for_this_step, $base_duration
      end
    end
    puts
    
    @next.go
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
          :midi => midi,
          :next => nil,
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