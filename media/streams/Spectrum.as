/*

	This class is used to hold stream properties

*/
package bitfade.media.streams {
	
	import flash.media.*
	import flash.events.*
	import flash.net.URLRequest
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Spectrum extends bitfade.media.streams.Audio {
	
		public function Spectrum() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Spectrum");
		}
		
		override public function get type():String {
			return "Spectrum"
		}
		
		
	}
}
/* commentsOK */