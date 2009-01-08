#This file gets loaded in for each measure so you should hear your changes soon afterward
#
# The @now variable shouldn't be used in this file, it gets passed from PR to PR via the
# call to go(@now).  Because evolve_probs gets called from inside go, the @now variable
# is visible in the improvs.rb file getting read in.
$options_have_loaded = true
#puts "reloading options"


@step_tick = L {|current,bpm,spbeat|
  result = 60.0/bpm.to_f/spbeat.to_f
  result
}

@measure_tick = L {|current,bpm,bpmeas|
  result = 60.0*bpmeas.to_f/bpm.to_f
  result
}

#$pr_player_note_range = (0..127)
$pr_player_note_range = (36..110)
#$base_duration = 0.4   #i need to redo this to be tempo i guess
$send_midi_clock = false
$bpm = 400 #beats per minute (really!)
$beats_per_measure = 4
$steps_per_beat = 1  #sequencer steps per beat
$steps_per_measure = $steps_per_beat * $beats_per_measure #sequencer steps per measure


#$interval = 60.0 / $bpm
#@timer = MIDIator::Timer.new( $interval / 10 )

$step_dt = @step_tick[0,$bpm,$steps_per_beat]

$measure_dt = @measure_tick[0,$bpm,3]

#puts "bpm: #{$bpm} bpmeas: #{$beats_per_measure} spb: #{$steps_per_beat} sdt:#{$step_dt} mdt: #{$measure_dt}"

#@scale_name = :major_scale
@scale = @root_note.send(@scale_name)
@chord, @chord_name = @chord_picker[@scale,@degree,@scale.valid_chord_names_for_degree(1).pick]
@roll = {} # name*note*step  (each improv lambda gets its own 2-d piano roll to paint with probys)
@improv = {} #to contain different improv strategies i guess.. i only have @improv[:chords] right now.

#puts @now
#@degree_picker = L {|prev| [nil,3,5,6,nil,1,2,][prev]} 3 6 2 5 1 ring
#@degree_picker = L {|prev| [nil,4,5,6,7,1,2,3][prev]}  3 6 2 5 1 4 7 ring
#@degree_picker = L {|prev| [nil,4,nil,nil,5,1][prev]}  1 4 5 ring
#@degree_picker = L {|prev,scale_name| 1}
#@degree_picker = L {|prev,scale_name| rand(6) + 1}


wrap_around = L {|x| L{|y| y>x ? y-x : y<1 ? y+x : y }} # keeps the degrees within a specified range
related_picker = L {|prev,scale_name| 
  a = [-3,-2,0,2,3].pick + prev
  wrap_around[14][a] #gives 2 octaves of room
}

@degree_picker = related_picker




@play = L { |opts|
  notes = opts[:notes]
  duration = opts[:duration]
  wheen = opts[:wheen]
  timer = opts[:timer]
  measure = opts[:measure]
  step = opts[:step]
  pr = opts[:pr]
   
  #notes,duration,wheen,timer,measure,step,pr|  
  wheen += @start
  #puts timer
  timer.at(wheen) { 
    #puts "\a" if measure == 1 and step == 0
    #puts "#{@root_note.name} #{@scale_name}, degree #{@degree},  #{@chord_name}" if measure == 1
    puts "#{measure}.#{step+1} #{notes.inspect.to_s} #{wheen} #{duration}"
    @midi.play notes, duration
    }  
}
