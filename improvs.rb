#This file is read in during every call to evolve_probs for live-editing
$improvs_have_loaded = true
#puts "reloading improvs"
#self.class = PianoRoll is our scope.


#supposedly I'm doing all this so the next chord is visible

puts "(current) #{@degree} -> #{@next.degree} (next)"

#improv lambdas which can paint the piano roll however they want.
#the piano roll has a @next pointing to the next measure's piano roll, whose
# root_note, scale, and chord are known and accessible data at this point.
#I'm thinking a bassline improv lambda could ask what the next measure's
# piano roll's chord is and then decide how best to walk towards it as it
# paints the current piano roll.  sort-of sight-reading

@note_name_match = L {|foo,note| foo.contains_note_names_of?(Note.new(note))}
@note_value_match = L {|foo,note| foo.contains_note_value?(note)}
@pov = L {|foo,pr|}

@init_improv = L {|opts,pr|
  if !pr.roll.has_key?(opts[:name])
     pr.roll[opts[:name]] = {}
     pr.roll[opts[:name]][:channel] = opts[:channel] || 0
     pr.roll[opts[:name]][:probs] = {}
     (0..127).each{|n| pr.roll[opts[:name]][:probs][n] = [0.0] * 4}
   end
}

@improv[:chords] = L do |opts|
  @init_improv[opts,self]  
  a = [1.0,1.0,1.0,0.0]
  b = [0.99,rand,rand,rand]
  probs = b # [a,b].pick
  opts[:pov].each do |note|  
    if opts[:test][chord,note]
      #pr.roll[name][note] = probs.map{|n| n + rand(5)*0.1}
      roll[opts[:name]][:probs][note] = probs.map{|n| rand}
    end 
  end
end   


@improv[:bassline] = L do |opts|
  @init_improv[opts,self]
  puts chord_name
  a = [0.6,0.3,0.5,0.3]
  b = [0.9,0.8,0.7,0.8]
  c = [rand,rand,rand,rand]
  d = [1.0] * 4
  probs = [a,b,c,d].pick
  probs = d
  opts[:pov].each do |note|
    if Note.new(note).name == chord.notes.first.name #scale.degree(degree).value
      roll[opts[:name]][:probs][note] = probs
    end
  end
end


#one note at a time for this particular lead improv (notice candidates.pick to single out the one)
@improv[:lead] = L do |opts|
  @init_improv[opts,self]
  (0..3).each{ |step|
    simult = opts[:simult] || 1    
    #puts simult
    if simult == 1
      candidates = opts[:pov].select{|n| opts[:test][scale,n]}
    else
      candidates = opts[:pov].select{|n| opts[:test][chord,n]}
    end  
    simult.times {  roll[opts[:name]][:probs][candidates.pick][step] = rand } }
end              

@improv[:clash] = L do |opts|
  @init_improv[opts,self] and puts "MUHAHAHAH!!! RAAAAHW!"
  opts[:pov].each { |note| roll[opts[:name]][:probs][note] = [nil,nil,nil,nil].map{|n| rand/2} }              
end

# end of defining the lambdas
######################################################
# actually invoking them below


#actually calling the lambdas here 
#@improv[:chords][:name => :chords1, :test => @note_value_match,:pov => chord.notes.first.value..chord.notes.last.value]


#@improv[:chords][:name => :chords2, :test => @note_name_match, :channel => 0, :pov => chord.notes.first.value..chord.notes.last.value]

#@improv[:lead][:name => :a, :channel => 0, :test => @note_name_match, :simult => 1, :pov => (33..45)]
#@improv[:lead][:name => :b, :channel => 0, :test => @note_name_match, :simult => 1, :pov => (46..55)]
@improv[:lead][:name => :c, :channel => 0, :test => @note_name_match, :simult => 3, :pov => (56..77)]
@improv[:lead][:name => :d, :channel => 0, :test => @note_name_match, :simult => 2, :pov => (78..88)]
@improv[:lead][:name => :e, :channel => 2, :test => @note_name_match, :simult => 2, :pov => (77..88)]
#@improv[:lead][:name => :f, :channel => 0, :test => @note_name_match, :simult => 1, :pov => (88..99)]

@improv[:bassline][:name => :boots, :channel => 1, :test => @note_name_match, :simult => 1, :pov => (44..66)]


#DANGER, this improv is SPOOOOKY
#@improv[:clash][:name => :clash, :channel => 0, :pov => [(50..65),(75..90),(80..95)].pick]
          