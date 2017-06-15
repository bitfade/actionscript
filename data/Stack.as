/*
	Stack data structure manager
*/
package bitfade.data {
	
	public class Stack {
	
		public var head:LLNode;
		public var cursor:LLNode
		
		public function Stack() {
		}
		
		// save a node 
		public function push(node:LLNode):LLNode {
			node.next = head
			return head = node
		}
		
		// get a node
		public function pop():LLNode {
			cursor = head
			
			if (cursor) {
				head = cursor.next
			} 
			return cursor
		}
		
		// merge a list
		public function merge(l:LinkedList):void {
			if (!l || l.empty) return
			// append all nodes from l to this
			l.tail.next = head
			head = l.head.next
			
			// remove nodes from l
			l.tail = l.head
			l.head.next = undefined
			l.rewind()
		}
		
		// tell if stack is empty
		public function get empty() {
			return head == null
		}
		
	}
}
/* commentsOK */