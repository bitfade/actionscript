/*
	this are helper functions used to centralize calls to ENTER_FRAME
*/
package bitfade.utils { 

	import flash.display.*
	import flash.events.*
	import flash.utils.*
	import bitfade.core.ITickable
	
	public class ticker {
	
		protected var list:Dictionary
		protected var dummy:Shape
		protected var active:uint = 0
	
		private static var _instance:ticker
	
		public function ticker() {
			list = new Dictionary(true)
			dummy = new Shape()
			events.add(dummy,Event.ENTER_FRAME,ticks)
		}
	
		public static function register(target:ITickable,scale:Number = 1):void {
			if (!_instance) _instance = new ticker()
			_instance.add(target,scale)
		}
		
		public static function unregister(target:ITickable):void {
			if (!_instance) return
			_instance.remove(target)
		}
	
		protected function add(target:ITickable,scale:Number):void {
			var tI:tickInfo = new tickInfo()
			tI.scale = scale
			list[target] = tI
			active++
		}
		
		protected function remove(target:ITickable):void {
			if (!list[target]) return
			delete list[target]
			if (--active == 0) {
				_instance = undefined
				Gc.destroy(dummy)
			}
		}
		
		protected function ticks(e:Event):void {
			var current:tickInfo
			for (var t:Object in list) {
				current = list[t]
				if (current.scale != 1) {
					current.count += current.scale
					if (current.count >= 1) {
						current.count %= 1
						t.tick()
					}
				} else {
					t.tick()
				}
			}
		}
				
	}
}

import flash.utils.*

internal class tickInfo {
	public var count:Number = 1
	public var scale:Number = 0	
}