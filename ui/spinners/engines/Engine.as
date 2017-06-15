/*

	Pure actionscript 3.0 spinner

*/
package bitfade.ui.spinners.engines { 
	
	import flash.display.*
	import flash.utils.*
	import bitfade.ui.spinners.Spinner
	import bitfade.utils.*
	
	public class Engine  {
		
		protected var bData:BitmapData
		
		protected static var _instance:Engine
		protected var db:Dictionary
		protected var registered:uint = 0
		
		protected var delayedDestroy:*
		
		public function Engine() {
			init()
		}
		
		protected function init():void {
			db = new Dictionary(true)
			build()
			Run.every(Run.FRAME,tick)
		}
		
		protected function build() {
		}
		
		public static function register(s:bitfade.ui.spinners.Spinner):void {
			_instance._register(s)
		}
		
		public static function unregister(s:bitfade.ui.spinners.Spinner):void {
			if (!_instance) return
			_instance._unregister(s)
		}
		
		protected function _register(s:bitfade.ui.spinners.Spinner):void {
			db[s] = true
			s.bitmapData = bData
			registered++
			Run.reset(delayedDestroy)
		}
		
		public function _unregister(s:bitfade.ui.spinners.Spinner):void {
			if (!s || !db[s]) return
			s.bitmapData = null
			delete db[s]
			if (--registered == 0) {
				delayedDestroy=Run.after(60,destroy,delayedDestroy)
			}
		}
		
		public function destroy():void {
			Run.reset(tick)
			if (bData) bData.dispose()
			_instance = null
		}
		
		public function tick():void {
		}
	}
}
/* commentsOK */