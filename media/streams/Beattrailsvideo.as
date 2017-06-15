/*

	This class is used to hold stream properties

*/
package bitfade.media.streams {
	
	import flash.media.*
	import flash.events.*
	import flash.net.URLRequest
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Beattrailsvideo extends bitfade.media.streams.Video {
	
		public function Beattrailsvideo() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Beattrailsvideo");
		}
		
		override public function get type():String {
			return "Beattrails"
		}
		
		
	}
}
/* commentsOK */