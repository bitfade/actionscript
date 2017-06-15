/*

	Beat Wall intro background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.geom.*
	import flash.events.*
	import flash.utils.*
	import flash.media.*
	import flash.filters.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.intros.backgrounds.Background
	
	public class BeatWall extends bitfade.intros.backgrounds.Background {
		
		protected var computeLoop:RunNode
		
		// bmap holding the beats
		protected var bMap:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bBar:BitmapData
		protected var bMask:BitmapData
		protected var pixelMatrix:BitmapData
		
		protected var power:uint = 0
		protected var cT:ColorTransform
		protected var bF:BlurFilter
		
		// constructor
		public function BeatWall(...args) {
			configure.apply(null,args)
		}
		
 
		// init the beat detector
		override protected function init():void {
			
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
		
			// create bitmaps
			bData = new BitmapData(w,h,true,0)
			bMap.bitmapData = bData
			
			bBar = new BitmapData(w,h,true,0)
			
			bMask = new BitmapData(w/16,h/16,true,0)
			
			pixelMatrix = new BitmapData(16,16,true,0)
			
			cT = new ColorTransform(1,1,1,1,0,0,0,0)
			bF = new BlurFilter(4,4,1);
			
			var sh:Shape = new Shape()
			
				
			var n:uint = 128			
			var mat:Matrix = new Matrix()
			
			// set colors
			var color1:uint = 0x404040
			var color2:uint = 0xFFFFFF
			var color3:uint = 0x404040
			
			
			if (conf.style == "light") {
				
				color1 = 0x808080
				color2 = 0x808080
				color3 = 0x808080
			
			}
			
			// create the gfx
			mat.createGradientBox(w*2,2*h, Math.PI/2,-w,-h);
		
			var bw:uint = w/16
			var bh:uint = h/16
			var xp:uint,yp:uint
			
			for (xp = 0; xp<w; xp+= bw) {
				for (yp = 0; yp<h; yp+= bh) {
				
					sh.graphics.beginGradientFill(GradientType.RADIAL, 
				[color1,color2,color3],
				[1,1,0],
				[0,128,255],
				//[0,254,255],
				mat,"pad","rgb");
				
					sh.graphics.drawRect(xp,yp,bw-1,bh-1)
					
					sh.graphics.endFill()
				}
            }
            
            
		
			sh.graphics.lineStyle(1,0,1);
			
			mat.createGradientBox(w*2,2*h, Math.PI/2,-w,-h);
			sh.graphics.lineGradientStyle(GradientType.RADIAL, 
				[0xFFFFFF,0xFFFFFF,0xFFFFFF],
				[.5,.3,0],
				[0,200,255],
				mat,"pad","linear")
				
            
            for (xp = 0; xp<w; xp+= bw) {
				for (yp = 0; yp<h; yp+= bh) {
					
					sh.graphics.moveTo(xp,yp+bh-1)
					sh.graphics.lineTo(xp,yp)
					sh.graphics.lineTo(xp+bw-1,yp)
				}
            }
            
   
			bBar.draw(sh)

		}
		
		override public function start():void {
			// add the event listener
			computeLoop = Run.every(Run.FRAME,computeSpectrum)
		}
		
		
		override public function burst(...args):void {
		}
		
		// this will draw the spectrum
		protected function computeSpectrum():void {
			// bData is not ready ? do nothing
			
			if (paused) return
			
			var beats:Array = Beat.detect().beats
			
			bData.lock()
			bData.fillRect(bData.rect,0)
			
			var bw:uint = w/16
			var bh:uint = h/16
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			var idx:uint = 0;
			
			var pM:BitmapData = pixelMatrix
			
			
			
			var fadeOut:Number = Math.min(0.95,Math.max(1-3*power/256,.7))
			
			cT.alphaMultiplier = fadeOut
			pM.colorTransform(pM.rect,cT)
			
			power = 0;
			
			for (xp = 0;xp<16;xp++) {
				for (yp = 0;yp<16;yp++) {
					if (beats[idx] > 0) {
						//pM.setPixel32(xp,yp,beats[idx] << 24)
						pM.setPixel32(xp,yp,0xFF << 24)
						power++
						//pM.setPixel32(Math.random()*16,Math.random()*16,0xFF << 24)
					} 
					idx++
				}
			}
			
			pM.applyFilter(pM,pM.rect,Geom.origin,bF)
			
			var pixValue:uint = 0;
			
			for (xp = 0;xp<16;xp++) {
				for (yp = 0;yp<16;yp++) {
					pixValue = pM.getPixel32(xp,yp)
					if (pixValue > 0) {
						bMask.fillRect(bMask.rect,pixValue)
						bData.copyPixels(bBar,Geom.rectangle(xp*bw,yp*bh,bw,bh),Geom.point(xp*bw,yp*bh),bMask,Geom.origin,false)
					}
				}
			}
			
			bData.unlock()
			
			
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */