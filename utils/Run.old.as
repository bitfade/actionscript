/*
	this are helper functions used to run delayed functions
*/
package bitfade.utils { 

	import flash.utils.*
	import bitfade.utils.*
	import bitfade.core.ITickable
	
	public class run implements bitfade.core.ITickable {
	
		private static var _instance:run = null
		private var active:uint = 0
		
		private var head:linkedList 
		private var tail:linkedList
		
		private var minTime:uint = uint.MAX_VALUE 
		
		public function run() {
			tail = head = new linkedList()
			ticker.register(this)
		}
		
		public static function after(delay:Number,callBack:Function,entry:linkedList = undefined,overwrite:Boolean=true):linkedList {
			if (!_instance) _instance = new run()
			return _instance.add(delay,callBack,entry,overwrite)
		}
		
		public static function reset(el:linkedList):void {
			if (_instance && el) el.disabled = true
		}
		
		protected function add(delay:Number,callBack:Function,entry:linkedList,overwrite:Boolean):linkedList {
		
			var append:Boolean = true
		
			if (entry) {
				if (entry.deleted) {
					// this entry has been deleted, we need to requeue it
					entry.deleted = false
				} else {
					// this entry has not been yet deleted
					// if overwrite is disabled, do nothing
					if (!overwrite) return entry
					// just update values
					append = false
				}	
			} else {
				entry = new linkedList()
			}
		
			entry.disabled = false
			entry.callBack = callBack
			entry.runAt = delay*1000+getTimer()
			
			// update minTime, if needed
			if (entry.runAt < minTime) minTime = entry.runAt
			
			// append entry, if needed
			if (append) {
				entry.next = undefined
				tail = tail.next =  entry
			}
			
			active++
			
			return entry
		}
		
		public function tick():void {
			
			var time:uint = getTimer()
			
			// if time is less than first function to be executed, do nothing 
			if (time < minTime) return
			
			minTime = uint.MAX_VALUE
			
			var cursor:linkedList = head.next
			var prev:linkedList = head
			
			while (cursor) {
				if (cursor.disabled || time > cursor.runAt ) {
					
					if (!cursor.disabled) cursor.callBack()
					
					cursor.deleted = true
					cursor.callBack = undefined
					prev.next = cursor.next
					cursor = prev.next
					
					if (!cursor) tail = prev
					
					if (tail === head) {
						_instance = undefined
						ticker.unregister(this)
						return
					}
				} else {
					if (cursor.runAt < minTime) minTime = cursor.runAt
					prev = cursor
					cursor = cursor.next
				}
			}
			
		}
	}
}


internal class linkedList {
	public var id: uint
	public var next: linkedList
	public var callBack: Function
	public var runAt:uint
	public var disabled:Boolean = false
	public var deleted:Boolean = false
}