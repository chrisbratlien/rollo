#This file is read in during every call to evolve_probs for live-editing

#improv lambdas which can paint the piano roll however they want.
#the piano roll has a @next pointing to the next measure's piano roll, whose
# root_note, scale, and chord are known and accessible data at this point.
#I'm thinking a bassline improv lambda could ask what the next measure's
# piano roll's chord is and then decide how best to walk towards it as it
# paints the current piano roll.  sort-of sight-reading

@match_by_name = L {|chord,note| chord.contains_note_names_of?(Note.new(note))}
@match_by_value = L {|chord,note| chord.contains_note_value?(note)}

@improv[:chords] = L{ |pr,name,test|

  spark = [1.0,1.0,1.0,0.0]

  if !pr.roll.has_key?(name)
    pr.roll[name] = {}
  end          
  (60..84).each do |note|  
    if !pr.roll[name].has_key?(note)
      pr.roll[name][note] = [0.0] * 4
    end
    if test[chord,note] #pr.chord.contains_note_value?(note)
      pr.roll[name][note] = spark.map{|n| n + rand(5)*0.1}
    end
  end
}   

