#This file gets loaded in for each measure
#@degree_picker = L {|prev| [nil,3,5,6,nil,1,2,][prev]} 3 6 2 5 1 -> ring
#@degree_picker = L {|prev| [nil,4,5,6,7,1,2,3][prev]}  3 6 2 5 1 4 7 -> ring
#@degree_picker = L {|prev| [nil,4,nil,nil,5,1][prev]}
@degree_picker = L {|prev,scale_name| 1}
@degree_picker = L {|prev,scale_name| rand(6) + 1}
@degree_picker = L {|prev,scale_name| [prev-2,prev,prev+2,prev+3,prev+4].pick % 7 }

#of course some degree pickers maybe should consider the scale.  maybe that'll be another parameter
# to the degre_picker, if you want to use it.
