/*

	Tween effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.utils.*
	import flash.geom.*
	
	public class Blocks extends bitfade.effects.Tween {
	
		protected var bMaskData:BitmapData;
		protected var bMask:Bitmap;
		
		protected var w:uint = 0;
		protected var h:uint = 0;
	
		// constructor
		public function Blocks(t:DisplayObject = null) {
			super(t)
		}
		
		public static function create(...args):Effect {
			return Effect.factory(bitfade.effects.Blocks,args)
		}
		
		// set destination values
		public function show(...args):Effect {
			
			target.alpha = 0
			target.cacheAsBitmap = true
			worker = worker_block
			
			w = target.width
			h = target.height
			
			bMaskData = Bdata.create(w,h)
			bMask = new Bitmap(bMaskData)
			bMask.cacheAsBitmap = true
			
			bMaskData.fillRect(new Rectangle(0,0,100,100),0x80FFFFFF)
			
			addChild(bMask)
			
			target.mask = bMask;
			
			return this
		}
		
		// compute tween values
		protected function worker_block(time:Number):void {
			bMaskData.lock()
			
			var bw:uint = w/8;
			var bh:uint = h/8;
			
			bMaskData.lock()
			
			for (var xp:uint=0;xp<w; xp+=bw) {
				for (var yp:uint=0;yp<h; yp+=bh) {
					bMaskData.fillRect(Geom.rectangle(xp,yp,bw,bh),Math.min(0xFF,uint(0xFF*time+32*(yp/h+xp/w))) << 24)
				}
			}
			bMaskData.unlock()
			
			target.mask = bMask
			//target.alpha = time
			target.alpha = 1
		}
		
		// destruct effect
		override public function destroy():void {
			target.mask = undefined
			//Gc.destroy(bMaskData)
			
			var idx:uint = parent.getChildIndex(this)
			parent.addChildAt(target,idx)
			target.cacheAsBitmap = false
			super.destroy()
		}

				
	}
}
/* commentsOK */