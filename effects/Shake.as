/*

	Shake effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.easing.*
	import bitfade.utils.Beat
	
	public class Shake extends bitfade.effects.Effect {
	
		// needed bitmaps
		protected var bShake1:Bitmap;
		protected var bShake2:Bitmap;
		
		protected var shakePower:Number = 0
		protected var shakeAngle:Number = 0
	
		// constructor
		public function Shake(t:DisplayObject = null) {
			super(t)
		}
		
		public static function create(...args):Effect {
			return Effect.factory(Shake,args)
		}
		
		// set destination values
		public function followMusic(...args):Effect {
			
			// create the bitmaps
			bShake1 = new Bitmap(target["bitmapData"])
			bShake2 = new Bitmap(target["bitmapData"])
			
			bShake1.x = bShake2.x = target.x
			bShake1.y = bShake2.y = target.y
			
			bShake1.blendMode = bShake2.blendMode = "add"
			
			bShake1.alpha = bShake2.alpha = 0
			
			addChild(bShake1)
			addChild(bShake2)
		
			worker = worker_shake
			
			return this
		}
		
		// compute the effect
		protected function worker_shake(time:Number):void {
		
			var power:Number = Beat.detect().beats[256]
			
			bShake1.blendMode = "normal"
			bShake2.blendMode = "add"
			
			
			if (power < shakePower) {
				shakePower -= 10
				
				if (shakePower < 0) shakePower = 0
				
				power = shakePower
			} else {
				shakePower = power
				shakeAngle = Math.random()*2*Math.PI
			
			}
			
			var palpha:Number = Math.min(.4,4*power/0xFF)
			
			bShake1.alpha = palpha
			bShake2.alpha = palpha * 0.5
			
			target.alpha = 1 - palpha
 			//target.alpha = 1
			
			var radious:Number = 15*power/0xFF
						
			bShake1.x = target.x + Math.sin(shakeAngle)*radious
			bShake2.x = target.x - Math.sin(shakeAngle)*radious
			
			bShake1.y = target.y + Math.cos(shakeAngle)*radious
			bShake2.y = target.y - Math.cos(shakeAngle)*radious
			
		
		}
		
		// destroy effect
		override public function destroy():void {
			// add child
			
			var idx:uint = parent.getChildIndex(this)
			parent.addChildAt(target,idx)
			
			bShake1.bitmapData = undefined
			bShake2.bitmapData = undefined
			
			target.alpha = 1
			
			super.destroy()
		}
				
	}
}
/* commentsOK */