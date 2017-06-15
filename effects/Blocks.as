/*

	Tween effect

*/
package bitfade.effects {
	
	import flash.display.*
	
	import bitfade.effects.*
	import bitfade.utils.*
	import bitfade.easing.*
	import flash.geom.*
	import flash.filters.*
	
	public class Blocks extends bitfade.effects.Tween {
	
		protected var bData:BitmapData;
		protected var bMask:BitmapData;
		protected var bMap:Bitmap;
		protected var bAdd:Bitmap;
		
		protected var w:uint = 0;
		protected var h:uint = 0;
		
		protected var xB:uint = 10;
		protected var yB:uint = 8;
		
		protected var pixelMatrix:BitmapData
		
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
			
			pixelMatrix = new BitmapData(xB+1,yB+1,true,0)
			
			
			
			buildBitmaps()
			
			speeds = new Array((xB+1)*(yB+1))
			
			var pM:BitmapData = pixelMatrix
			
			var bw:uint = w/xB;
			var bh:uint = h/yB;
			var idx:uint = 0;
			var s:Number = 0;
			
			for (var xp:uint=0;xp<=xB; xp++) {
				for (var yp:uint=0;yp<yB; yp++) {
					if (Math.random() > 0.8) pM.setPixel32(xp,yp,0xFF << 24)
				}
			}
			
			pM.applyFilter(pM,pM.rect,Geom.origin,new BlurFilter(4,4,1))
			
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
			
			bAdd.alpha = 2*time < 1 ? time : 2-2*time
			bAdd.alpha = 1-alpha
			//trace(bAdd.alpha)
			//bAdd.alpha = 1;
			bAdd.alpha = 0;
			
			var pM:BitmapData = pixelMatrix
			
			var idx:uint = 0;
			var bAlpha:uint = 0;
			var bAlpha2:uint = 0;
			var s:uint = 0;
			var c:uint = 0;
			var ix:uint = 0;
			var iy:uint = 0;
			
			/*
			for (var xp:uint=0;xp<=xB; xp++) {
				for (var yp:uint=0;yp<yB; yp++) {
					pM.setPixel32(xp,yp,time*0xFF*Math.random() << 24)
				}
			}
			*/
			
			
			//pM.applyFilter(pM,pM.rect,Geom.origin,new BlurFilter(4,4,1))
			
			pM.applyFilter(pM,pM.rect,Geom.origin,new ConvolutionFilter(3,3,
			[ 1,1,1,
              1,1,1,
               1,1,1 ],8.5,0,false))
			
			//pM.colorTransform(pM.rect,new ColorTransform(1,1,1,1,0,0,0,5))
			
			
			for (var xp:uint=0;xp<w; xp+=bw,ix++) {
				iy = 0;
				for (var yp:uint=0;yp<h; yp+=bh,iy++) {
					s = pM.getPixel32(ix,iy)
					bAlpha = Math.min(0xFF,((s >>> 24) + (time*0xFF))) << 24
					c = s >>> 24
					bAlpha2 = Math.min(0xFF,1.1*c)
					bMask.fillRect(Geom.rectangle(xp,yp,bw,bh),bAlpha | 0)
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