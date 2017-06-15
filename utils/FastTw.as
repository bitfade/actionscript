/*
	Simple and fast tween engine
*/
package bitfade.utils { 

	import flash.utils.*
	import bitfade.easing.*
	import bitfade.core.*

	public dynamic class FastTw extends Proxy implements bitfade.core.IDestroyable {
		
		public var target:Object
		
		protected var start:uint = 0
		protected var duration:Number = 0.5
		protected var delay:Number = 0
		protected var runOnce:Boolean = false
		public var running:Boolean = false;
		
		protected var autoHide:Boolean = true;
		protected var source:Object
		protected var destination:Object
		// default ease function
		public var ease:Function = bitfade.easing.Expo.Out
		
		private static var db:Dictionary
		private static var loop:RunNode
		
		public static function init() {
			db = new Dictionary()
			loop = Run.every(Run.FRAME,update)
		}
		
		// update all tweens
		protected static function update() {
			for each (var t:FastTw in db) {
				if (t.running) t.tick()
			}
		}
		
		// create/access a tween assigned to obj
		public static function tw(obj:*):FastTw {
			if (!loop) init()
			if (!db[obj]) {
				db[obj] = new FastTw(obj)
			}
			return db[obj]
		}
		
		// create a tween assigned to obj
		public static function once(obj:*):FastTw {
			var tween:FastTw = tw(obj)
			tween.params(0.5,null,true,true)
			return db[obj]
		}
		
		// remove a tween assigned to obj
		public static function remove(obj:*):void {
			if (db) {
				if (db[obj]) {
					db[obj].destroy()
				}	
			}
		}
		
		// set tween params
		public function params(duration:Number = 0.5,ease:Function = null,autoHide:Boolean = true,runOnce:Boolean = false) {
			this.duration = duration
			this.autoHide = autoHide
			this.runOnce = runOnce
			if (ease != null) this.ease = ease
		}
		
		// constructor
		public function FastTw(target:Object) {
			this.target = target
		}
 		
 		// proxy method to set obj properties
 		flash_proxy override function setProperty(prop:*,value:*):void {
			to(prop,value)
 		}
 		
 		// tween updater
 		public function tick() {
 			var elapsed:Number = (getTimer() - start)/1000
 			
 			if (elapsed > (duration-0.02)) elapsed = duration
 			
 			var ratio:Number = ease(elapsed, 0, 1, duration)
 			var value:Number
 			
 			for (var p:String in destination) {
				value = source[p] + (destination[p]-source[p])*ratio
				if (p == "x" || p == "y") value = int(value+0.5)
				if (p == "alpha" && autoHide) target.visible = (value > 0)
				
				target[p] = value
				//trace(p,value)
			}
 			
 			if (elapsed == duration) {
 				running = false
 				if (runOnce) remove(target)
 			}
 		}
 		
 		public function stop():void {
 			running = false
 		}
 		
 		public function destroy():void {
			
			delete db[this.target]
			target = undefined
			
			var empty:Boolean = true
					
			for (var key:* in db) {
				empty = false;
				break;
			}

			if (empty) {
				db = undefined
				loop = Run.reset(update)
			}
	
 		}
 		
 		public function to(p:String,v:Number) {
 			if (!source) source = {}
 			if (!destination) destination = {}
 			destination[p] = v
 			source[p] = target[p]
 			start = getTimer()
 			running = true
 		}
 		
	}
}
/* commentsOK */