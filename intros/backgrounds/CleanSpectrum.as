/*

	Spectrum intro background

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
	
	public class CleanSpectrum extends bitfade.intros.backgrounds.Background {
		
		protected var computeLoop:RunNode
		
		// bmap holding the spectrum
		protected var bMap:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bBuffer:BitmapData
		protected var bBar:BitmapData
		
		// constructor
		public function CleanSpectrum(...args) {
			configure.apply(null,args)
		}
		
 
		// init the spectrum
		override protected function init():void {
			
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
		
			bMap.blendMode = "add"
			bMap.alpha = 1
		
			// create bitmaps
			bData = new BitmapData(w,h,true,0)
			bMap.bitmapData = bData
			
			bBuffer = new BitmapData(w,h,true,0)
			
			bBar = new BitmapData(w,h,true,0)
			
			var sh:Shape = new Shape()
			
				
			sh.graphics.clear()
			var n:uint = 128			
			var mat:Matrix = new Matrix()
			
			sh.graphics.lineStyle(1,0,1);
			
			mat.createGradientBox(w*1.4,2*h, Math.PI/2,-w/1.4,-h);
			var color1:uint = 0x00FF00
			var color2:uint = 0xFF0000
			var color3:uint = 0x0000FF
			
			color1 = 0xFFFFFF
			color2 = 0x404040
			color3 = 0
			
			sh.graphics.lineGradientStyle(GradientType.RADIAL, 
				[color1,color2,color3],
				[.5,.3,0],
				[0,200,255],
				mat,"pad","linear")
				
				
			mat.createGradientBox(w*1.4,2*h, Math.PI/2,-w/1.4,-h);
			sh.graphics..beginGradientFill(GradientType.RADIAL, 
				[color1,color2,color3],
				[1,.5,0],
				[0,128,255],
				mat,"pad","rgb");
			
			sh.graphics.drawRect(0,0,w,h)
			sh.graphics.endFill()
            
            
            for (var xp:uint = 0; xp<w; xp+= uint(w/16)) {
            	sh.graphics.moveTo(xp,0)
			
				sh.graphics.lineTo(xp,h)
            }
            
            for (var xp:uint = 0; xp<h; xp+= uint(h/16)) {
            	sh.graphics.moveTo(0,xp)
			
				sh.graphics.lineTo(w,xp)
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
			
			var beats:Array = Beat.detect()
						
			bBuffer.colorTransform(bData.rect,new ColorTransform(1,1,1,0.9,0,0,0,0))
			
			var bw:uint = w/16
			var bh:uint = h/16
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			var count:uint = 0;
					
			//bw = 4
			//bh = 4
			
			//trace(Math.abs(8-5/Math.pow(2,5*1/subbands)),Math.abs(8-5/Math.pow(2,5)))
			
			for (var i:uint=0;i<=255;i++) {
				if (beats[i] > 0) {
				
					bBuffer.copyPixels(bBar,Geom.rectangle(xp,yp,bw-1,bh-1),Geom.point(xp,yp),null,null,true)					
					count++
					
					/*
					xp +=bw

				
					if ((i % 16 == 0) ) {
						xp = 0
						yp += bh
						//bw = w/16
							
					}
					*/
					
				} else {
					//if (test[i] != 0) trace("ERROR 0",i,test[i])
				}
				
				xp +=bw

				
				if (((i+1) % 16 == 0) ) {
					xp = 0
					yp += bh
					//bw = w/16
						
				}
				
				/*
				xp += bw
					
					
				if (xp > w || (i % 16 == 0) ) {
					xp = 0
					yp += bh
					//bw = w/16
						
				} else {
					//bw -= 2

				}
				*/
				

			}
			
			bData.copyPixels(bBuffer,bData.rect,Geom.origin)
			
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */