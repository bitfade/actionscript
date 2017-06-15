/*
	effect's queue entry
*/
package bitfade.effects.queue { 

	import bitfade.data.LLNode
	import bitfade.effects.Effect
	
	public final class EffectQueueNode extends bitfade.data.LLNode {
		public var method: Function
		public var params: Array
	}

}
/* commentsOK */