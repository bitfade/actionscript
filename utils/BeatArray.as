/*
	detects beats of current played sound
*/
package bitfade.utils {

	import flash.utils.ByteArray
	import flash.media.SoundMixer

	public class Beat {
	
		// number of frequencies
		public static const subbands:uint = 256;
		
		// previous values
		protected static const historyLength:uint = 25
	
		// instance
		protected static var _instance:Beat
		
	
		// raw data
		protected var spectrumData:ByteArray;
		protected var instant:Array 
		protected var average:Array
		protected var quad:Array
		protected var variance:Array 
		protected var history:Array
		protected var beats:Array
		
		// round robin buffer position
		protected var rrbp:uint = 0
		
		public function Beat():void {
			init()					
		}
		
		protected function init() {
			spectrumData = new ByteArray()
			spectrumData.position = 0;
			
			instant = new Array(subbands)
			average = new Array(subbands)
			quad = new Array(subbands)
			history = new Array(subbands)
			variance = new Array(subbands)
			beats = new Array(subbands)
			
			for (var i:uint=0;i<subbands;i++) {
				average[i] = 0
				variance[i] = 0
				quad[i] = 0
				history[i] = new Array(historyLength)
				for (var j:uint=0;j<historyLength;j++) history[i][j] = 0;
				
			}

		}
		
		public static function detect():Array {
			if (!_instance) _instance = new Beat()
			return _instance.compute()
		}
		
		// compute current played spectrum and return beats arrays
		protected function compute():Array {
		
			var randomData:Boolean = true
			
			spectrumData.position = 0;
			
			if (!SoundMixer.areSoundsInaccessible()) {
				try {
					SoundMixer.computeSpectrum(spectrumData, true, 0);
					randomData = false
				} catch (e:*) {}
			}
			
			var instantV:Number,prevD:Number;
			var i:uint,j:uint;
			
			var averageV:Number,varianceV:Number,quadV:Number,out:Number
			var intensity:Number,varianceThreshold:Number,intensityThreshold:Number
			
			// left channel
			for (i=0;i<subbands;i++) {
				instant[i] = spectrumData.readFloat();
			}
			
			
			for (i=0;i<subbands;i++) {
				// add right channel 
				
				prevD = instant[i]
				instantV = spectrumData.readFloat()
				
				// get the max from left,right
				instantV = instantV < prevD ? prevD : instantV
				
				// normalize
				instantV *= 50
				instant[i] = instantV
				
				// update history
				out = history[i][rrbp]
				history[i][rrbp] = instantV
				
				averageV = average[i] - out
				averageV += instantV
				average[i] = averageV
				
				quadV = quad[i] - out*out
				quadV += instantV*instantV
				quad[i] = quadV
				
				
				varianceV = instantV*(instantV*historyLength-2*averageV) + quadV
				
				variance[i] = varianceV
				
				intensity = historyLength*instantV/averageV
				//varianceThreshold = (100+400/Math.pow(2,5*i/subbands))*historyLength
				varianceThreshold = (100+400/Math.pow(2,5*i/subbands))*historyLength
				//varianceThreshold = 400*historyLength
				
				
				intensityThreshold = 1
				
				
				
				if (varianceV > varianceThreshold && intensity > intensityThreshold) {
					beats[i] = uint(0xFF*intensity/50)
				} else {
					//trace("HERE",i)
					beats[i] = 0
				}
				
			}
			
			rrbp = (rrbp + 1) % historyLength
			
			
			return beats
			
		}
			
	}

}
/* commentsOK */


