/*

	Base class for intro's backgrounds

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import bitfade.utils.*
	import bitfade.core.IDestroyable
	
	public class Background extends Sprite implements bitfade.core.IDestroyable {
		
		protected var w:uint = 0
		protected var h:uint = 0
		protected var paused:Boolean = false
		protected var conf:Object
		
		public function background(...args) {
		}
		
		protected function configure(...args):void {
			w = args[0]
			h = args[1]
			conf = args[2]
			
			mouseEnabled = false
			mouseChildren = false
			
			init()
		}
		
		// init the background
		protected function init():void {
		}
		
		// callback when background ready
		public function onReady(cb:Function) {
			cb()
		}
		
		// set gradient
		public function gradient(scheme:String = null,immediate:Boolean = false) {
		}
		
		// draw burst
		public function burst(...args):void {
		}
		
		// start display
		public function start():void {
		}
		
		// end display
		public function end():void {
		}
		
		// pause
		public function pause():void {
			paused = true
		}
		
		// play
		public function play():void {
			paused = false
		}
		
		public function resume():void {
			play()
		}
		
		// clean up
		public function destroy():void {
			Gc.destroy(this)
		}
		
		public function show(content:*,opts:Object = null):void {}
		
		public static function get resourceType():String {
			return null
		}
				
	}

}
/* commentsOK */