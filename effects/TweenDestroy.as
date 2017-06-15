/*

	Tween effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.utils.*
	
	public class TweenDestroy extends bitfade.effects.Tween {
	
		// constructor
		public function TweenDestroy(t:DisplayObject = null) {
			super(t)
		}
		
		public static function create(...args):Effect {
			return Effect.factory(TweenDestroy,args)
		}
		
		// destruct effect
		override public function destroy():void {
			if (target) Gc.destroy(target)
			super.destroy()
		}

				
	}
}
/* commentsOK */