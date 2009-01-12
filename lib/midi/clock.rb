# get singleton from std lib
module Archaeopteryx
  module Midi
    class Clock # < Singleton
      attr_reader :time, :interval, :start, :syncs_per_measure, :syncs_per_step, :steps_per_measure
      def initialize(bpm)
       # assumes 16-step step sequencer, 4/4 beat, etc.
        self.bpm = bpm
        @start = Time.now.to_f
        @time = 0.0
      end
      def bpm=(bpm)
        #$send_midi_clock = true
        @sync_tick = L{ |bpm,syncs_per_qn|
          60.0/bpm.to_f/syncs_per_qn.to_f
        }

        @step_tick = L {|bpm,spbeat|
        60.0/bpm.to_f/spbeat.to_f
        }

        @measure_tick = L {|bpm,bpmeas|
        60.0*bpmeas.to_f/bpm.to_f
        }
        
        @qtr_per_measure = 4
        @steps_per_qtr = 1  #sequencer steps per beat  #TR-909 would have 4 for this
        @steps_per_measure = @steps_per_qtr * @qtr_per_measure #sequencer steps per measure
        @syncs_per_qtr = 24   #MIDI clock syncs to send to Reason etc
        @syncs_per_measure = @syncs_per_qtr * @qtr_per_measure
        @syncs_per_step = @syncs_per_qtr / @steps_per_qtr
        @step_dt = @step_tick[bpm,@steps_per_qtr]
        @measure_dt = @measure_tick[bpm,@qtr_per_measure]
        @sync_dt = @sync_tick[bpm,24]

        @interval = @sync_dt
        
        #seconds_in_a_minute = 60.0
        #beats_in_a_measure = 4.0
        #@interval = seconds_in_a_minute / bpm.to_f / beats_in_a_measure
      end
      def sync_tick
        
        
        @time += @sync_dt
        @time
      end
    end
  end
end

