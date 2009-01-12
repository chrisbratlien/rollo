require 'rubygems'
require 'midiator'

midi = MIDIator::Interface.new
midi.autodetect_driver

#shush
(0..127).each{|n| midi.driver.note_off(n,0,0) }
