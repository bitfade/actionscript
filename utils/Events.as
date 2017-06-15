/*
	this are helper functions used add/remove events
*/
package bitfade.utils { 

	import flash.events.*
	
	import flash.utils.getQualifiedClassName
	import flash.utils.Dictionary
	
	import bitfade.data.*
	
	public class Events {
	
		private var queue:LinkedList
		private var node:eventNode
		private var seen:Dictionary
		
		private static var _instance:Events
		
		public function Events() {
			queue = new LinkedList()
			seen = new Dictionary(true)
		}
		
		// call this to add one or more event listeners to an object
		public static function add(target:IEventDispatcher,evt:*,callBack:Function,owner:IEventDispatcher = null):void {
			if (_instance == null) _instance = new Events()
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
			
			node = new eventNode()
			
			node.target = target
			node.owner = owner
			node.events = evt
			node.callBack = callBack
			
			queue.append(node)
			
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
		
			queue.rewind()
			
			while(node = queue.next) {
				if (node.target === target || node.owner === target ) {
					
					for each (var event in node.events) {
						try {
							node.target.removeEventListener(event,node.callBack)
						} catch (e) {}
					}
					queue.deleteCurrent()
				} 
			}
			
			if (queue.empty) {
				_instance = undefined
			}
		}
	}
}

import flash.events.IEventDispatcher

internal class eventNode extends bitfade.data.LLNode {
	public var target: IEventDispatcher
	public var events: Array
	public var callBack: Function
	public var owner:IEventDispatcher
	
}
/* commentsOK */