/*

	Pure actionscript 3.0 text back light effect with xml based configuration.
	this extends bitfade.text.effect which has common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	import bitfade.display.ExtBitmapData
	
	
	public class light extends bitfade.text.effect {

		// light box variables
		private var lPos:int;
		private var lIncr:int;
		private var lMin:int;
		private var lMax:int;
		
		// drop shadow filter
		private var dsF;
		
		// used to draw lines
		private var bBuffer2:ExtBitmapData;
		
		// use default constructor
		public function light(conf) {
			super(conf)
		}
		
		// destructor
		override protected function destroy() {
			removeEventListener(Event.ENTER_FRAME,updateEffect)
			super.destroy()
		}
		
		// custom init
		override protected function customInit() {
			
			// create the filter
			dsF = new DropShadowFilter(w,0,0,1,8,8,1.8,2,false,false,false)
			
			// create ExtBitmapData
			bBuffer2 = new ExtBitmapData(w,h,true,0);
						
			// use "add" blend mode
			bMap.blendMode="add"
			
			// effect updater
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		// custom text updated
		override protected function textUpdated()  {
			
			// initialize light box
			
			lMax = hitR.width*2+pt.x
			lMin = pt.x-hitR.width
			
			lPos = lMin
						
			lIncr = uint(hitR.width*3/currTransition.duration)
 			
		}
		
		// custom transition update
		override protected function transitionUpdated() {
			// change filter strength if needed
			dsF.strength = currTransition.intensity ? currTransition.intensity : 1.8
		}
		
		// here is the magic
		public function updateEffect(e=null) {
			
			// if not ready, do nothing
			if (!ready) return
			
			// some variables used to move the light box
			var xp:uint
			var yp:uint
			
			var xs:uint = pt.x
			var ys:uint = pt.y
			
			var xm:uint = hitR.width 
			var ym:uint = hitR.height
			
			var yc:uint = h/2
			var xc:uint = w/2
			
			
			var x1:uint
			var x2:int
			var y1:uint
			var y2:int
			
			
			var sA:uint = 0
			
			
			var searchBoxSize:uint = currTransition.density ? Math.max(2,currTransition.density) : 4
			
			var r = new Rectangle(0,0,searchBoxSize,searchBoxSize)
			
			// clear stuff
			bBuffer2.fillRect(box,0)
			
			// now, for every 4x4 box which contains pixels with alpha > 0, cast rays
			for (xp = 0;xp<xm;xp += searchBoxSize) {
				r.x = xp
				
				x1 = xs+xp+2
				x2 = x1+(x1-lPos)*2
				sA = uint((xm-Math.min(Math.abs(x1-lPos),xm))*0x80/xm)
				
				
				if (Math.abs(x2-x1)< 32) {
					x2 += (x1<x2) ? 16 : -16
				} 
						
				
				if (sA > 20)
				for (yp = 2;yp<ym;yp += searchBoxSize) {
				
					r.y = yp
					if (bDraw.hitTest(origin,0x01,r)) {
					
						y1 = ys+yp+2
				
						y2 = y1+(y1-yc)*10
						
						bBuffer2.line(x1,y1,x2,y2,0,sA,1)
						
					}
				
				}

			}
			
			// deal with different glow types 
			switch (currTransition.glow) {
				case "fade":
						sA = uint((xm-Math.min(Math.abs(xc-lPos),xm))*0xFF/xm)
						bBuffer.fillRect(box,sA << 24)
						bBuffer2.copyPixels(bDraw,hitR,pt,bBuffer,origin,true)
					break
				case "full":
						bBuffer2.copyPixels(bDraw,hitR,pt,null,null,true)
					break
				default:
			}
			
			// apply filter
			origin.x = -w;
			bBuffer.applyFilter(bBuffer2,box,origin,dsF)
			origin.x = 0
			bBuffer.copyPixels(bDraw,hitR,pt,bBuffer,pt,true)
			
			bData.lock()
			// use our colormap
			bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			bData.unlock()
			
			// if light box reach end
			if (lPos > lMax || lPos < lMin) {
				if (currText.pass == 1) {
					updateText()
				} else {
					if (currText.pass != "infinite") currText.pass--
					if (lPos > lMax ) lIncr = -Math.abs(lIncr)
					if (lPos < lMin ) lIncr = Math.abs(lIncr)
					lPos += lIncr
				}
			} else {
				lPos += lIncr
			}
		}
		
		
	
	}

}
	