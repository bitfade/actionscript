/*
	detects beats of current played sound
*/
package bitfade.utils {

	import flash.utils.*
	import flash.media.SoundMixer

	public class Beat {
	
		// number of frequencies
		public static const subbands:uint = 257;
		
		// previous values
		protected static const historyLength:uint = 25
	
		// instance
		protected static var _instance:Beat
		
		public var beats:Array
		
		// raw data
		protected var spectrumData:ByteArray;
		protected var average:Array
		protected var quad:Array
		protected var history:Array
		
		// round robin buffer position
		protected var rrbp:uint = 0
		
		protected var sampled:uint = 0;
		protected var lastComputation:int = 0
		protected var lastBeat:int = 0
		protected var totalPower:Number = 0
		
		public function Beat():void {
			init()					
		}
		
		protected function init() {
			spectrumData = new ByteArray()
			spectrumData.position = 0;
			
			average = new Array(subbands)
			quad = new Array(subbands)
			history = new Array(subbands)
			beats = new Array(subbands)
			
			for (var i:uint=0;i<subbands;i++) {
				average[i] = 0
				quad[i] = 0
				history[i] = new Array(historyLength)
				for (var j:uint=0;j<historyLength;j++) history[i][j] = 0;
				
			}

		}
		
		public function get power():Number {
			return totalPower
			//return beats[256];
		}
		
		public static function detect():Beat {
			if (!_instance) _instance = new Beat()
			return _instance.compute()
		}
		
		// compute current played spectrum and return beats arrays
		protected function compute():Beat {
		
			var now:int = getTimer()
		
			if (now-lastComputation < 20) return this
		
			lastComputation = now
		
			var randomData:Boolean = true
			
			spectrumData.position = 0;
			
			if (!SoundMixer.areSoundsInaccessible()) {
				try {
					SoundMixer.computeSpectrum(spectrumData, true, 0);
					randomData = false
				} catch (e:*) {}
			}
			
			//trace(spectrumData.length)
			
			var instantV:Number,leftV:Number;
			var i:uint,j:uint;
			
			var averageV:Number,varianceV:Number,quadV:Number,out:Number
			var intensity:Number,varianceThreshold:Number,intensityThreshold:Number
			var inv50:Number = 1/50;
			var varianceRampFactor:Number = 5/subbands
			
			var totalPower:Number = 0
			var sumV:Number = 0
			var totalBeats:uint = 0
	
			
			if (sampled < historyLength) sampled++
			
			spectrumData.position = 0
			
			for (i=0;i<subbands;i++) {
			
				if (i < 256) {
					if (randomData) {
						instantV = Math.random()*0.5
					} else {
						// left channel			
						spectrumData.position = i << 2;
						leftV = spectrumData.readFloat()
						
						// right channel 
						spectrumData.position = (256+i) << 2
						instantV = spectrumData.readFloat()
						
						// get the max from left,right
						instantV = instantV < leftV ? leftV : instantV
					}
						
					// normalize
					instantV *= 50
					
					if (i<256) sumV += instantV
						
				} else {
					instantV = sumV
				}
				
				totalPower += instantV
				
				// update history
				out = history[i][rrbp]
				history[i][rrbp] = instantV
				
				averageV = average[i] - out
				averageV += instantV
				average[i] = averageV
				
				quadV = quad[i] - out*out
				quadV += instantV*instantV
				quad[i] = quadV
				
				
				varianceV = instantV*(instantV*sampled-2*averageV) + quadV
				
				
				intensity = sampled*instantV/averageV
				varianceThreshold = (100+400/Math.pow(2,i*varianceRampFactor))*sampled
				
				intensityThreshold = 1
				
				if (i == 256) {
					varianceThreshold = sampled*10000
					intensityThreshold = 1
				}
				
				
				if (varianceV > varianceThreshold && intensity > intensityThreshold) {
					beats[i] = uint(0xFF*intensity*inv50)
					totalBeats++
				} else {
					beats[i] = 0
				}
				
			}
			
			if (beats[256] > 0 && now-lastBeat<150) {
				beats[256] = 0
			}
			
			if (beats[256] > 0) {
				beats[256] = totalBeats
				lastBeat = now
				
			} 
			rrbp = (rrbp + 1) % historyLength
			
			this.totalPower = totalPower/50
			
			return this
			
		}
			
	}

}
/* commentsOK */


