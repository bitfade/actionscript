/*
	this are helper functions used add/remove events
*/
package bitfade.utils { 

	import flash.events.*
	
	import flash.utils.getQualifiedClassName
	import flash.utils.Dictionary
	
	public class events {
	
		private var head:linkedList 
		private var tail:linkedList
		private var seen:Dictionary
		
		private static var _instance:events
		
		public function events() {
			tail = head = new linkedList()
			seen = new Dictionary(true)
		}
		
		// call this to add one or more event listeners to an object
		public static function add(target:IEventDispatcher,evt:*,callBack:Function,owner:IEventDispatcher = null):void {
			if (!_instance) _instance = new events()
			_instance._add(target,evt,callBack,owner)
		}
		
		// remove all registered event listeners for an object
		public static function remove(target:*):void {
			if (!_instance) return
			_instance._remove(target)
		}
		
		protected function _add(target:IEventDispatcher,evt:*,callBack:Function,owner:IEventDispatcher) {
			if (target === null) return
		
			if (evt is String) evt = [evt]
			
			tail = tail.next =  new linkedList()
			
			tail.target = target
			tail.owner = owner
			tail.events = evt
			tail.callBack = callBack
			
			seen[target] = true
			if (owner) seen[owner] = true
			
			for (var i:int=evt.length-1;i >=0;i--) {
				target.addEventListener(evt[i],callBack,false,0,true)
			}
		}
		
		// remove all registered event listeners for an object
		protected function _remove(target:*):void {
		
			if (!seen[target]) return
		
			delete seen[target]
		
			var cursor:linkedList = head.next
			var prev:linkedList = head
			
			while (cursor) {
				if (cursor.target === target || cursor.owner === target ) {
					
					for each (var event in cursor.events) {
						try {
							cursor.target.removeEventListener(event,cursor.callBack)
						} catch (e) {}
					}
				
					prev.next = cursor.next
					cursor.target = cursor.owner = undefined
					cursor.callBack = undefined
					cursor = prev.next
					
					if (!cursor) tail = prev
					
					if (tail === head) {
						// empty list, clean stuff
						_instance = undefined
						return
					}
					
				} else {
					prev = cursor
					cursor = cursor.next
				}
			}						
		}
	}
}

import flash.events.IEventDispatcher

internal class linkedList {
	public var next: linkedList
	public var target: IEventDispatcher
	public var events: Array
	public var callBack: Function
	public var owner:IEventDispatcher
	
}