/*

	Tween effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.utils.*
	import bitfade.easing.*
	import flash.geom.*
	
	public class Blocks extends bitfade.effects.Tween {
	
		protected var bData:BitmapData;
		protected var bMask:BitmapData;
		protected var bMap:Bitmap;
		protected var bAdd:Bitmap;
		
		protected var w:uint = 0;
		protected var h:uint = 0;
		
		protected var xB:uint = 10;
		protected var yB:uint = 8;
		
		protected var speeds:Array;
	
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
			worker = worker_block
			
			w = target.width
			h = target.height
			
			yB = 8
			xB = yB*w/h
			
			buildBitmaps()
			
			speeds = new Array((xB+1)*(yB+1))
			
			var bw:uint = w/xB;
			var bh:uint = h/yB;
			var idx:uint = 0;
			var minS:Number = Number.MAX_VALUE;
			var maxS:Number = Number.MIN_VALUE;
			var s:Number = 0;
			for (var xp:uint=0;xp<w; xp+=bw) {
				for (var yp:uint=0;yp<h; yp+=bh) {
					s = 0.1+Math.random()*0.9
					//s = 0.1+(xp/w)*(yp/h);
					if (s < minS) minS = s
					if (s > maxS) maxS = s
					speeds[idx] = s
					
					idx++
				}
			}
			
			var d:Number = maxS - minS;
			
			while (idx--) {
				speeds[idx] = 0.1+0.9*(speeds[idx]-minS)/d
			}
			
			return this
		}
		
		protected function buildBitmaps() {
			bData = Bdata.create(w,h)
			bMask = Bdata.create(w,h)
			bMap = new Bitmap(bData)
			bAdd = new Bitmap(bMask)
			bAdd.blendMode = "add"
			addChild(bMap)
			addChild(bAdd)
		}
		
		
		// compute tween values
		protected function worker_block(time:Number):void {
			var bw:uint = w/xB;
			var bh:uint = h/yB;
			
			//bAdd.alpha = 2*time < 1 ? time : 2-2*time
			bAdd.alpha = 1-alpha
			//trace(bAdd.alpha)
			//bAdd.alpha = 1;
			
			var idx:uint = 0;
			var bAlpha:uint = 0;
			var bAlpha2:uint = 0;
			var s:Number = 0;
			var c:uint = 0;
			for (var xp:uint=0;xp<w; xp+=bw) {
				for (var yp:uint=0;yp<h; yp+=bh) {
					s = speeds[idx]
					if (time >= s ) {
						bAlpha = 0xFF
					} else {
						bAlpha = Linear.Out(time,0,0xFF,s);
					}
				
					bAlpha2 = bAlpha << 1
					if (bAlpha2 > 0xFF) bAlpha2 = 0xFF
					c = 0xFF*s
					bMask.fillRect(Geom.rectangle(xp,yp,bw,bh),bAlpha << 24 | c << 16 | c << 8 | c)
					//bMask.fillRect(Geom.rectangle(xp,yp,bw,1),bAlpha2 << 24 | 0xFFFFFF)
					//bMask.fillRect(Geom.rectangle(xp,yp,1,bh),bAlpha2 << 24 | 0xFFFFFF)
					idx++
				}
			}
			
			bData.copyPixels(Bitmap(target).bitmapData,bData.rect,Geom.origin,bMask,Geom.origin)
			
		}
		
		// destruct effect
		override public function destroy():void {
			//Gc.destroy(bMaskData)
			bMask.dispose();
			target.alpha = 1
			var idx:uint = parent.getChildIndex(this)
			parent.addChildAt(target,idx)
			super.destroy()
		}

				
	}
}
/* commentsOK */