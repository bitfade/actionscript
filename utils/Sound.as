/*
	compute the spectrum of current played sound
*/
package bitfade.utils {

	import flash.utils.ByteArray
	import flash.media.SoundMixer

	public class Sound {
	
		// raw data
		public static var spectrumData:ByteArray = new ByteArray()
		
		// levels values
		public static var levels:Array = new Array(6)
		
		// frequency values 
		public static var freqs:Array = new Array(256)
		
		// current sound power
		public static var power:Number = 0
		
		// number of non zero frequency
		public static var activeFreqs:uint = 0
	
		// compute current played spectrum and return freqs/levels arrays
		public static function computeSpectrum():void {
			
			spectrumData.position = 0;
			// get the data
			
			var randomData:Boolean = true
			
			if (!SoundMixer.areSoundsInaccessible()) {
				try {
					SoundMixer.computeSpectrum(spectrumData, true, 1);
					randomData = false
				} catch (e:*) {}
			}
			
			// frequency step for levels
			var step:uint = 16
			
			// some variables needed later
			var i:uint 
			var sd:Number
			var count:uint = 0;
			var p:uint = 0
			var gc:uint
			
			// reset values
			power = 0
			for (i=0;i<6;i++) levels[i] = 0
			activeFreqs = 0
			
			// compute
			for (i=0;i<=255;i++,gc++) {
				// get frequency value
				sd = randomData ? Math.random()*0.5 : spectrumData.readFloat()
				freqs[i] = sd 
				
				if (sd > 0) {
					// if value > 0, add it to current level
					count++
					activeFreqs++
					levels[p] = Math.max(levels[p],sd)
				} 
					
				// go to next level
				if (gc >= step || i == 255) {
					// increase power
					power += levels[p]
					p++
					gc = 0
					count = 0
					// increase step
					step = uint(step*1.5)
				}
				
			}
			
			
		}
			
	}

}
/* commentsOK */