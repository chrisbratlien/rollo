#This file gets loaded in for each measure so you should hear your changes soon afterward

#$pr_player_note_range = (0..127)
$pr_player_note_range = (36..110)
$base_duration = 2.0


#@scale_name = :major_scale
@scale = @root_note.send(@scale_name)
@chord, @chord_name = @chord_picker[@scale,@degree,@scale.valid_chord_names_for_degree(1).pick]
@roll = {} # improv*note*step  (each improv lambda gets its own 2-d piano roll to paint with probys)
@improv = {} #to contain different improv strategies i guess.. i only have @improv[:chords] right now.



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
