require 'midiator'

@midi = MIDIator::Interface.new
@midi.autodetect_driver
@timer = MIDIator::Timer.new(100000)
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

     
  (0..$syncs_per_measure-1).each do |sync|      
    # Send MIDI Clock (aka Midi Sync in Propellerhead Reason)
    if sync % $syncs_per_step == 0
      step = sync / $syncs_per_step          
      collect_for_this_step = {}
      $pr_player_note_range.each do |note|
        @roll.keys.each do |name|
          chan = @roll[name][:channel]
          collect_for_this_step[chan] = [] if !collect_for_this_step[chan]
          if rand < @roll[name][:probs][note][step]
            collect_for_this_step[chan] << note
          end  
        end
      end
      @timer.at(@start + @now) do          
        $syncs_per_step.times {@midi.driver.clock}
        collect_for_this_step.keys.each do |chan|      
          puts "channel #{chan} #{collect_for_this_step[chan].inspect.to_s}"
          @midi.play(collect_for_this_step[chan],0.25,chan,100)
        end
      end        
    end
    @now += $sync_dt
  end
end
