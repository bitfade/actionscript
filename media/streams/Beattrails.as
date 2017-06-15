/*

	This class is used to hold stream properties

*/
package bitfade.media.streams {
	
	import flash.media.*
	import flash.events.*
	import flash.net.URLRequest
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Beattrails extends bitfade.media.streams.Audio {
	
		public function Beattrails() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Beattrails");
		}
		
		override public function get type():String {
			return "Beattrails"
		}
		
		
	}
}
/* commentsOK */