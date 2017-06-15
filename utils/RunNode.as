/*
	run entry
*/
package bitfade.utils { 

	import bitfade.data.LLNode
	
	public class RunNode extends bitfade.data.LLNode {
		public var callBack: Function
		public var callBackValues:Boolean = false
		public var extraParameter:*
		public var repeatCount:uint = 0
		public var repeatMax:int = 0
		public var repeatDelay:uint = 0
		public var runAt:uint
		public var disabled:Boolean = false
		public var deleted:Boolean = false
		public var pauseStart: uint = 0
	}

}
/* commentsOK */