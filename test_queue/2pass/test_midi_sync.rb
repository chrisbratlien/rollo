alias :L :lambda
require 'midiator'

@midi = MIDIator::Interface.new
@midi.autodetect_driver
@timer = MIDIator::Timer.new(0.0001)
puts "And a..."
     
@sync_tick = L{ |bpm,syncs_per_qn|
  60.0/bpm.to_f/syncs_per_qn.to_f
}

@step_tick = L {|bpm,spbeat|
60.0/bpm.to_f/spbeat.to_f
}

@measure_tick = L {|bpm,bpmeas|
60.0*bpmeas.to_f/bpm.to_f
}

#$pr_player_note_range = (0..127)
$pr_player_note_range = (36..110)
#$base_duration = 0.4   #i need to redo this to be tempo i guess
$send_midi_clock = true
$bpm = 150 #beats per minute (really!)
$qtr_per_measure = 4
$steps_per_qtr = 1  #sequencer steps per beat
$steps_per_measure = $steps_per_qtr * $qtr_per_measure #sequencer steps per measure
$syncs_per_qtr = 24   #MIDI clock syncs to send to Reason etc
$syncs_per_measure = $syncs_per_qtr * $qtr_per_measure
$syncs_per_step = $syncs_per_qtr / $steps_per_qtr

#$interval = 60.0 / $bpm
#@timer = MIDIator::Timer.new( $interval / 10 )

$step_dt = @step_tick[$bpm,$steps_per_qtr]
$measure_dt = @measure_tick[$bpm,3]
$sync_dt = @sync_tick[$bpm,24]

@start = Time.now.to_f
@now = 0.0
        
@midi.driver.message(0xFA)

while true
  queue = []
  (0..$syncs_per_measure-1).each do |sync|      
    # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
    if sync % $syncs_per_step == 0
      step = sync / $syncs_per_step       

      #puts queue[step].inspect.to_s
      queue[step] = [[60,0,0.25,100]]
      queue[step].each do |x|
        n,c,d,v = x      
        puts "channel #{c} #{n},#{d},#{v}"
        @timer.at(@start + @now) { @midi.note_on(n,c,v) }

        @timer.at(@start + @now + d) {@midi.note_off(n,0) }
      end
    end
    #puts "huzzuh"
    @timer.at(@start + @now) { @midi.driver.message(0xF8) }
    @now += $sync_dt
  end
end