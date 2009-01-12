#This file is read in during every call to evolve_probs for live-editing
$improvs_have_loaded = true
puts "reloading improvs"
#self.class = PianoRoll is our scope.

#improv lambdas which can paint the piano roll however they want.
#the piano roll has a @next pointing to the next measure's piano roll, whose
# root_note, scale, and chord are known and accessible data at this point.
#I'm thinking a bassline improv lambda could ask what the next measure's
# piano roll's chord is and then decide how best to walk towards it as it
# paints the current piano roll.  sort-of sight-reading

@note_name_match = L {|foo,note| foo.contains_note_names_of?(Note.new(note))}
@note_value_match = L {|foo,note| foo.contains_note_value?(note)}
@pov = L {|foo,pr|}

@init_improv_pr = L {|name,pr|
  if !pr.roll.has_key?(name)
     pr.roll[name] = {}
     (0..127).each{|n| pr.roll[name][n] = [0.0] * 4}
   end
}

@improv[:chords] = L do |opts|
  @init_improv_pr[:chords,self]  
  a = [1.0,1.0,1.0,0.0]
  b = [0.99,rand,rand,rand]
  probs = a # [a,b].pick
  opts[:pov].each do |note|  
    if opts[:test][chord,note]
      #pr.roll[name][note] = probs.map{|n| n + rand(5)*0.1}
      roll[:chords][note] = probs.map{|n| rand}
    end 
  end
end   


#one note at a time for this particular lead improv (notice candidates.pick to single out the one)
@improv[:lead] = L do |opts|
  @init_improv_pr[:lead,self]
  (0..3).each{ |step|
    simult = opts[:simult] || 1    
    #puts simult
    if simult == 1
      candidates = opts[:pov].select{|n| opts[:test][scale,n]}
    else
      candidates = opts[:pov].select{|n| opts[:test][chord,n]}
    end  
    simult.times {  roll[:lead][candidates.pick][step] = rand } }
end              

@improv[:clash] = L do |opts|
  @init_improv_pr[opts[:name],self] and puts "MUHAHAHAH!!! RAAAAHW!"
  opts[:pov].each { |note| roll[:clash][note] = [nil,nil,nil,nil].map{|n| rand/2} }              
end

# end of defining the lambdas
######################################################
# actually invoking them below


#actually calling the lambdas here 
#@improv[:chords][:name => :chords, :test => @note_value_match,:pov => chord.notes.first.value..chord.notes.last.value]


#@improv[:chords][:name => :chords, :test => @note_name_match,:pov => chord.notes.first.value-24..chord.notes.last.value-7]


#@improv[:lead][:test => @note_name_match, :pov => [(68..77)].pick]@improv[:lead][:test => @note_name_match, :simult => rand(4)+1, :pov => [(48..77)].pick]




#DANGER, this improv is SPOOOOKY
#@improv[:clash][:name => :clash, :pov => [(50..65),(75..90),(80..95)].pick]
          