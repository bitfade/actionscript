/*
	this are helper functions used to run delayed functions
*/
package bitfade.utils { 

	import flash.utils.*
	import flash.display.Shape
	import flash.events.*
	import bitfade.utils.*
	import bitfade.data.*
	
	public class Run {
	
	
		public static const FOREVER:int = -1
		public static const FRAME:int = 0
	
		private static var _instance:Run = null
		
		protected var dummy:Shape
		
		private var queue:LinkedList
		private var node:RunNode
		
		private var minTime:uint = uint.MAX_VALUE 
		
		private var toBeDeleted:Dictionary
		
		private var destroyTimer: Timer
		
		public function Run() {
			queue = new LinkedList()
			dummy = new Shape()
			destroyTimer = new Timer(60000,1)
			Events.add(destroyTimer,TimerEvent.TIMER,destroy)
			Events.add(dummy,Event.ENTER_FRAME,tick)
			toBeDeleted = new Dictionary()
		}
		
		// run a delayed function 
		public static function after(delay:Number,callBack:Function,entry:RunNode = undefined,overwrite:Boolean=true,repeatMax:int=0,repeatDelay:Number=0,callBackValues:Boolean = false,extraParameter:* = null):RunNode {
			if (!_instance) _instance = new Run()
			return _instance.add(delay,callBack,entry,overwrite,repeatMax,repeatDelay,callBackValues,extraParameter)
		}
		
		// run function multiple times
		public static function every(repeatDelay:Number,callBack:Function,repeatMax:int=FOREVER,delay:Number = 0,callBackValues:Boolean = false,entry:RunNode = undefined,extraParameter:* = null):RunNode {
			if (!_instance) _instance = new Run()
			return _instance.add(delay,callBack,entry,true,repeatMax,repeatDelay,callBackValues,extraParameter)
		}
		
		// pause a timer
		public static function pause(el:RunNode):void {
			if (_instance && el) _instance.toggle(el,true)
		}
		
		// pause a timer
		public static function resume(el:RunNode):void {
			if (_instance && el) _instance.toggle(el,false)
		}
		
		public function toggle(el:RunNode,doPause:Boolean = false) {
			var time:uint = getTimer()
			if (el) {
				if (doPause) {
					el.pauseStart = time
				} else {
					if (el.pauseStart > 0) {
						el.runAt += time-el.pauseStart
						el.pauseStart = 0
					}
				}
			}
		}
		
		// reset a scheduled function
		public static function reset(el:*):RunNode {
			if (_instance && el) _instance.kill(el)
			return undefined
		}
		
		protected function kill(el:*):void {
			if (el is RunNode) {
				// if element is a node, just set it as disabled
				el.disabled = true
			} else {
				// if element is a function, record it for late delete
				toBeDeleted[el] = true
			}
			
		}
		
		protected function add(delay:Number,callBack:Function,entry:RunNode,overwrite:Boolean,repeatMax:int=0,repeatDelay:Number=0,callBackValues:Boolean = false,extraParameter:* = null):RunNode {
		
			var append:Boolean = true
			
			if (destroyTimer.running) destroyTimer.reset()
			
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
				entry = new RunNode()
			}
		
			entry.repeatCount = 0
			entry.repeatMax = repeatMax > 1 ? repeatMax-1 : repeatMax
			entry.repeatDelay = repeatDelay*1000
			entry.callBackValues = callBackValues
			
			entry.extraParameter = extraParameter
			entry.disabled = false
			entry.pauseStart = 0
			entry.callBack = callBack
			entry.runAt = delay*1000+getTimer()
			
			// update minTime, if needed
			if (entry.runAt < minTime) minTime = entry.runAt
			
			// append entry, if needed
			if (append) {
				queue.append(entry)
			}
			
			return entry
		}
		
		public function tick(e:Event):void {
			
			var time:uint = getTimer()
			
			// if time is less than first function to be executed, do nothing 
			if (time < minTime) return
			
			var deleteNode:Boolean
			var ratio:Number
			
			// set min time to max
			minTime = uint.MAX_VALUE
			
			queue.rewind()
			
			while (node = queue.next) {
				deleteNode = false
				
				if (node.disabled || toBeDeleted[node.callBack]) {
					delete toBeDeleted[node.callBack]
					deleteNode = true
				} else if (node.pauseStart > 0) {
					// do nothing
				} else if (time > node.runAt ) {
					if (node.callBackValues) {
						ratio = node.repeatMax > 0 ? node.repeatCount/node.repeatMax : node.repeatCount
						if (node.extraParameter !== null) {
							node.callBack(ratio,node.extraParameter)
						} else {
							node.callBack(ratio)
						}
					} else {
						node.callBack()
					}
					
					if (node.repeatCount == node.repeatMax) {
						deleteNode = true
					} else {
						node.repeatCount++
						node.runAt += node.repeatDelay
					}				
				}
				
				if (deleteNode) {
					node.deleted = true
					node.callBack = undefined
					queue.deleteCurrent()
				} else if (node.runAt < minTime) {
					minTime = node.runAt
				}
				
			}
			
			if (queue.empty) {
				destroyTimer.start()
			}
			
		}
		
		public function destroy(e:Event) {
			_instance = undefined
			Gc.destroy(dummy)
			Events.remove(destroyTimer)
		}
	}
}
/* commentsOK */