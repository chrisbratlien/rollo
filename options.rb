#This file gets loaded in for each measure so you should hear your changes soon afterward
#
# The @now variable shouldn't be used in this file, it gets passed from PR to PR via the
# call to go(@now).  Because evolve_probs gets called from inside go, the @now variable
# is visible in the improvs.rb file getting read in.
$options_have_loaded = true
#puts "reloading options"

@sync_tick = L{ |bpm,syncs_per_qn|
  60.0/bpm.to_f/syncs_per_qn.to_f
}

@step_tick = L {|bpm,spbeat|
60.0/bpm.to_f/spbeat.to_f
}

@measure_tick = L {|bpm,bpmeas|
60.0*bpmeas.to_f/bpm.to_f
}

$clock.bpm = 120

#$pr_player_note_range = (0..127)
$pr_player_note_range = (36..110)
#$base_duration = 0.4   #i need to redo this to be tempo i guess
$send_midi_clock = true
$midi_sync_offset = 0.0  #-0.45


#@scale_name = :major_scale
#@scale_name = :minor_pentatonic_scale
#@scale_name = favorite_scales[]

@scale = @root_note.send(@scale_name)

@chord,@chord_name = @chord_picker[@scale,@degree,@scale.valid_chord_names_for_degree(1).pick] if !@chord



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

@next_degree = @degree_picker[@degree,@scale_name]  #could also use old_pr.scale_name
@next_chord,@next_chord_name = @chord_picker[@scale,@next_degree,@scale.valid_chord_names_for_degree(1).pick]