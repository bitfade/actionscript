/*
	Linked list data structure manager with object pooling
*/
package bitfade.data {
	
	public class LinkedListPool extends LinkedList {
	
		// the pool will hold deleted nodes, so that they can be reused
		protected var pool:Stack
		
		protected var attributes:Array
		protected var nodeClass:Class
		
		
		public function LinkedListPool(nC:Class,...args) {
			super()
			nodeClass = nC
			
			if (args[0] is Stack) {
				pool = args[0]
				args.shift()
			} else {
				pool = new Stack()
			}
			
			attributes = args
		}
		
		// create a new node if needed, or get a pool entry
		public function create(...args):* {
			return (pool.empty ? new nodeClass() : pool.pop())
		}
		
		// get first node
		override public function shift(target:LLNode = undefined):LLNode {
			return pool.push(target ? copy(super.shift(),target) : super.shift())
		}
		
		// delete current node
		override public function deleteCurrent():LLNode {
			return pool.push(super.deleteCurrent())
		}
		
		public function repool():void {
			pool.merge(this)
		}
		
		// copy node attributes to target
		public function copy(node:LLNode,target:*):LLNode {
			var i:uint = attributes.length
			var p:String
			while (i--) {
				p = attributes[i]
				target[p] = node[p]
			}
			return node
		}
		
	}
}
/* commentsOK */