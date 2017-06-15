/*
	Linked list data structure manager
*/
package bitfade.data {
	
	public class LinkedList {
	
		public var head:LLNode;
		public var tail:LLNode;
		protected var keepCursorPosition:Boolean = false
		
		public var cursor:LLNode
		public var prev:LLNode
		
		protected var size:uint = 0
		
		public function LinkedList() {
			tail = head = new LLNode()
		}
		
		// append a node as last element
		public function append(node:LLNode):LLNode {
			if (!node) return undefined
			keepCursorPosition = false
			node.next = undefined
			size++
			return tail = tail.next =  node
		}
		
		// prepend a node as fist element (still untested)
		public function prepend(node:LLNode):LLNode {
			if (!node) return undefined
			keepCursorPosition = false
			node.next = head.next
			size++
			return head.next = tail.next =  node
		}
		
		// get first node and remove it from list
		public function shift(target:LLNode  = undefined):LLNode {
			cursor = head.next
			keepCursorPosition = false
			
			if (cursor) {
				head.next = cursor.next
				if (tail === cursor) tail = head
				size--
			} 
			return cursor
		}
		
		// delete current node
		public function deleteCurrent():LLNode {
			var deleted:LLNode
			if (cursor) {
				prev.next = cursor.next
				
				deleted = cursor
				deleted.next = undefined
				
				cursor = prev.next
				if (!cursor) tail = prev
				
				keepCursorPosition = true
				size--
			}
			return deleted
		}
		
		// rewind cursor to list head
		public function rewind():LLNode {
			keepCursorPosition = false
			cursor = head
			return head
		}
		
		// get next node
		public function get next():* {
			if (keepCursorPosition) {
				keepCursorPosition = false
			} else {
				prev = cursor
				if (cursor) {
					cursor = cursor.next
				}
			}
			return cursor
		}
		
		// tell if list is empty
		public function get empty() {
			return tail === head
		}
		
		// merge 2 lists
		public function merge(l:LinkedList):void {
			if (!l || l.empty) return
			// append all nodes from l to this
			tail.next = l.head.next
			cursor = tail = l.tail
			// remove nodes from l
			l.tail = l.head
			l.head.next = undefined
			l.rewind()
		}
		
		// nodes number
		public function get length():uint {
			return size
		}
		
		// destroy list by removing all links
		public function destroy(callBack:Function = null):void {
			keepCursorPosition = false
			cursor = head
			while (cursor) {
				prev = cursor
				cursor = cursor.next
				if (cursor && callBack != null) callBack(cursor)
				prev.next = undefined
			}
			tail = head = cursor = prev = undefined
			
		}
		
	}
}
/* commentsOK */