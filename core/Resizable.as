/*

	Base class for resizable widgets

*/
package bitfade.core {
	
	import bitfade.utils.*
	import bitfade.core.*
	
	import flash.display.*
	
	
	public class Resizable extends Sprite implements bitfade.core.IResizable,bitfade.core.IDestroyable {
	
		protected var w:uint = 0
		protected var h:uint = 0
		
		public function Resizable(...args) {
			super()
		}
			
		// resize component
		public function resize(nw:uint = 0,nh:uint = 0):void {
			w = nw
			h = nh
		}
		
		// destruct component
		public function destroy():void {
			Gc.destroy(this)
		}
		
	}
}
/* commentsOK */