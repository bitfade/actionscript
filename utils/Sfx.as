/*
	this are helper functions used to play sound effects
*/
package bitfade.utils { 

	import flash.events.*
	import flash.media.*
	import flash.system.*
	
	import flash.utils.*
	
	public class Sfx {
	
		private var queue:Dictionary
		private var owner:Dictionary
		
		private static var _instance:Sfx
		
		public function Sfx() {
			queue = new Dictionary()
			owner = new Dictionary()
		}
		
		public static function extract(ad:ApplicationDomain):Object {
		
			var sfxs:Object
		
			if (ad && ad is ApplicationDomain) {
				sfxs = {}
				var sounds:Array = ad.getDefinition("soundFxLibrary").sounds
				for each (var s:Class in sounds ) {
					sfxs[getQualifiedClassName(s).replace(/soundFxLibrary_/,"")] = s
				}
			}
			return sfxs 
		}
		
		// play a sound effect
		public static function play(snd:Class,volume:Number = 1,parent:* = null):void {
			if (_instance == null) _instance = new Sfx()
			_instance._add(snd,volume,parent)
		}
		
		public static function pauseAll(parent:* = null):void {
			if (_instance) _instance._pauseAll(parent)
		}
	
		public static function volumeAll(ratio:Number,parent:* = null):void {
			if (_instance) _instance._volumeAll(ratio,parent)
		}
	
		// add the effect to queue
		protected function _add(snd:Class,volume:Number = 1,parent:* = null) {
			
			if (snd === null) return
			
			var soundEffect: flash.media.Sound = new snd() as flash.media.Sound
			
			var ch: flash.media.SoundChannel = soundEffect.play()
			
			// set volume
			var st:SoundTransform = ch.soundTransform;
            st.volume = volume;
            ch.soundTransform = st;

			queue[ch] = soundEffect
			if (parent) owner[ch] = parent
			
			// add complete event handler
			Events.add(ch,[Event.SOUND_COMPLETE],sndComplete)
		}
		
		// whene complete, delete sound reference
		protected function sndComplete(e:Event):void {
			clean(flash.media.SoundChannel(e.target))
		}
		
		protected function _pauseAll(parent:* = null):void {
			for (var ch in queue) {
				if (!parent || owner[ch] == parent) {
					clean(flash.media.SoundChannel(ch))
				}
			}
		}
		
		protected function _volumeAll(ratio:Number=1,parent:* = null):void {
			for (var ch in queue) {
				if (!parent || owner[ch] == parent) {
					volume(flash.media.SoundChannel(ch),ratio)
				}
			}
		}
		
		protected function volume(ch:SoundChannel,ratio:Number) {
			var sf:SoundTransform = ch.soundTransform
			sf.volume = ratio
			ch.soundTransform = sf

		}
		
		
		protected function clean(ch:SoundChannel) {
			ch.stop()
			delete queue[ch]
			delete owner[ch]

		}
		
		
	}
}
/* commentsOK */