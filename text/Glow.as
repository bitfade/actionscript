/*

	Pure actionscript 3.0 progressive light glow effect with xml based configuration.
	this extends bitfade.text.effect which has common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	public class glow extends bitfade.text.effect {

		// light box variables
		private var lPos:int;
		private var lIncr:int;
		private var lMin:int;
		private var lMax:int;
		private var lRect:Rectangle;
		private var lP:Point,dsFp:Point
		
		// drop shadow filter
		private var dsF;
		
		// some bitmaps
		private var bBuffer2:BitmapData;
		private var bMask:BitmapData;
		
		// color transform 
		private var cT:ColorTransform
		
		// this will be set by xml conf
		private var glowArea:uint = 100;
		
		// use default constructor
		public function glow(conf) {
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
			
			// and bitmapdatas
			bBuffer2 = bData.clone()
			bMask = bData.clone()
			
			// some geom stuff
			lRect = new Rectangle()
			lP = new Point()
			dsFp = new Point(-w,0)
			
			// color transform
			cT = new ColorTransform(0,0,0,0.9,0,0,0,0)
			
			// use "add" blend mode
			bMap.blendMode="add"
			
			// effect updater
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		
		// custom text updated
		override protected function textUpdated() {
			
			// clean stuff
			bBuffer2.fillRect(box,0)
			
			// initialize light box
			
			lMax = hitR.width-1
			lMin = -glowArea+1
			
			lPos = lMin
						
			lIncr = uint((lMax-lMin)/currTransition.duration+0.5)
 			
 			lP.y = pt.y
 			lRect.height=hitR.height;
 			
 			
		}
		
		// custom transition update
		override protected function transitionUpdated() {
			
			// set filter parameters with transition values
			with (dsF) {
				strength = currTransition.glowIntensity ? currTransition.glowIntensity : 1.8
				blurX = blurY = currTransition.glowBlur ? currTransition.glowBlur : 8
 
			}
			
			// set glow area
			glowArea = (currTransition.glowArea > 0) ? currTransition.glowArea : 100
			
			// initialize rectangle
			with (lRect) {
				y=0
				width=1
				height=h;
			}
			
			var a:uint = 0
			
			// create the copy mask
			
			for (var xp:uint=0;xp<glowArea;xp += 1) {
				lRect.x = xp
				
				a = uint((glowArea-xp+1)*0x40/glowArea)
				bMask.fillRect(lRect,a << 24)
			}
			
			// set the colortransform with transition value
			cT.alphaMultiplier = currTransition.persistence ? currTransition.persistence/100 : 0.94
 			
		}
		
		// here is the magic
		public function updateEffect(e=null) {
			
			// if not ready, do nothing
			if (!ready) return
			
			// fade things out
			bBuffer2.colorTransform(box,cT);
			
			// starting x 
			var rx:uint = lPos > 0 ? lPos : 0
			
			lRect.x = rx 
			// box width
			lRect.width = (lPos < 0) ? lPos+glowArea : glowArea
			
			// destination point
			lP.x = pt.x+rx
			
			bBuffer2.copyPixels(bDraw,lRect,lP,bMask,new Point(glowArea-lRect.width,0),true)
			
			// apply filter
			bBuffer.applyFilter(bBuffer2,box,dsFp,dsF);
			
			
			bData.lock()
			bData.fillRect(box,0)
			bData.copyPixels(bDraw,hitR,pt,bBuffer,pt,true)
			bData.copyPixels(bBuffer,box,origin,null,null,true)
			// use our color map
			bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			bData.unlock()
			
			// if glow box reach end
			if (lPos > lMax) {
				if (currText.pass == 1) {
					updateText()
				} else {
					if (currText.pass != "infinite") currText.pass--
					lPos = lMin
				}
			} else {
				lPos += lIncr
			}
		}
		
		
	
	}

}
	