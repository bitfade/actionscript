/*

	This is a base class, nothing here

*/
package bitfade.media.visuals {
	
	import flash.display.*
	import flash.events.Event
	
	import bitfade.core.*
	import bitfade.utils.*
	
	
	public class Visual extends Sprite implements bitfade.core.IResizable,bitfade.core.IDestroyable {
		
		// max window size
		protected var maxW:uint = 0
		protected var maxH:uint = 0
		
		// true if playback is paused
		protected var paused:Boolean = false
		
		// scale mode
		protected var scaleMode:String = "none"
		
		// constructor
		public function Visual(w:uint=0,h:uint=0) {
			super()
			name = "visualizer"
			mouseEnabled = false
			mouseChildren = false;
		}
		
		// resize the visual
		public function resize(nw:uint = 0,nh:uint = 0):void {
			maxW = nw
			maxH = nh
			scale()
		}
		
		// set zoom mode
		public function zoom(s:String = "none"):void {
			scaleMode = s
		}
		
		// link the visualizer to a video stream 
		public function link(s:*):void {
		}
		
		// scale the visual
		protected function scale():void {}
		
		// pause the visual
		public function pause():void {
			paused = true
		}
		
		// pause the visual
		public function resume():void {
			paused = false
		}
		
		public function destroy():void {
			Gc.destroy(this)
		}
		
		public function get isDrawable():Boolean {
			return true
		}
		
	}
}
/* commentsOK */