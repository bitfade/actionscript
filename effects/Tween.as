/*

	Tween effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.easing.*
	
	public class Tween extends bitfade.effects.Effect {
	
		protected var source:Object
		protected var destination:Object
	
		// constructor
		public function Tween(t:DisplayObject = null) {
			super(t)
		}
		
		public static function create(...args):Effect {
			return Effect.factory(Tween,args)
		}
		
		// set destination values
		public function to(...args):Effect {
			destination = args[1]
			
			source = {}
			
			for (var p:String in destination) {
				source[p] = target[p]
			}
			
			worker = worker_tween
			
			return this
		}
		
		public function fadeIn(...args):Effect {
			return to(args[0],{alpha : 1})
		}
		
		public function fadeOut(...args):Effect {
			return to(args[0],{alpha : 0})
		}
		
		// compute tween values
		protected function worker_tween(time:Number):void {
			var value:Number		
			for (var p:String in destination) {
				value = source[p] + (destination[p]-source[p])*time
				if (p == "x" || p == "y") value = int(value+0.5)
				//this[p] = value
				
				target[p] = value
				
			}
		}
				
	}
}
/* commentsOK */