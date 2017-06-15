/*

	Pure actionscript 3.0 spinner

*/
package bitfade.ui.spinners { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.utils.*
	
	import bitfade.ui.spinners.engines.*
	import bitfade.core.IDestroyable
	import bitfade.utils.*
	
	public class Spinner extends Bitmap implements bitfade.core.IDestroyable {
		
		protected var delayedRun
		
		// constructor
		public function Spinner(opts:Object=null) {
			super()
			visible = false
			//show()
		}
		
		protected function getSize():Number {
			return 0
		}
		
		override public function get width():Number {
			return getSize()
		}
		
		override public function get height():Number {
			return getSize()
		}
		
  		protected function _show(e:Event=null):void {
  			visible = true
  			register() 			
  		}
  		
  		protected function register():void {
  		}
  		
  		// show spinner (after wait seconds)
		public function show(wait:Number = 0):void {
			if (!visible) {
				if (wait == 0) {
					_show()
				} else {
					delayedRun = Run.after(wait,_show,delayedRun,false)
				}
			
			}
		}
		
		// hide spinner
		public function hide():void {
			Run.reset(delayedRun)
			//delayedRun = undefined
			Engine.unregister(this)
			visible = false
		}
		
		// desctroy spinner
		public function destroy():void {
			hide()
			Gc.destroy(this)
		}
		
	}
}
/* commentsOK */