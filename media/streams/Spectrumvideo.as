/*

	This class is used to hold stream properties

*/
package bitfade.media.streams {
	
	import flash.media.*
	import flash.events.*
	import flash.net.URLRequest
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Spectrumvideo extends bitfade.media.streams.Video {
	
		public function Spectrumvideo() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Spectrumvideo");
		}
		
		override public function get type():String {
			return "Spectrum"
		}
		
		
	}
}
/* commentsOK */