/*

	Pure actionscript 3.0 motion blur light glow effect with xml based configuration.
	this extends bitfade.text.effect which has common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	public class blurGlow extends bitfade.text.effect {

		// some other bitmaps
		protected var bColor:BitmapData;
		protected var bMask:BitmapData;
		protected var bBuffer2:BitmapData;
		
		// color transform 
		protected var cT:ColorTransform
		
		// used to scale content
		protected var refM:Matrix
		protected var scaleIncr:Number
		protected var scale:Number
		
		
		// drop shadow filter
		protected var dsF;
		// blur filter
		protected var bF;
		// bevel filter
		protected var bevF;
		
		// light box variables
		protected var lPos:Number;
		protected var lIncr:Number;
		protected var lRect:Rectangle;
		protected var lP:Point
		
		protected var countdown:uint
		
		// use default constructor
		public function blurGlow(conf) {
			super(conf)
		}
		
		// destructor
		override protected function destroy() {
			removeEventListener(Event.ENTER_FRAME,updateEffect)
			super.destroy()
		}
		
		// custom init
		override protected function customInit() {
			// call parent customInit
			super.customInit();
			
			// create bitmapDatas
			bColor = bData.clone();
			bBuffer2 = bData.clone();
			bMask = bData.clone();
			
			// create drop shadow filter
			dsF = new DropShadowFilter(0,0,0,1,1,1,0.8,3,false,false,true)
			
			// create the blur filter
			bF = new BlurFilter(24,24,3)
			
			// create the bevel filter
			bevF = new BevelFilter(1,45,0xFFFFFF,1,0,1,1,1,1,3,"inner",false)
			
			
			// create the mask
			var sh:Shape = new Shape()
			
			with (sh.graphics) {
				beginFill(0,1) 
				drawRect(40,40,w-80,h-80)
			}
			
			bMask.draw(sh)
			bMask.applyFilter(bMask,box,origin,bF)
			
			// use "add" blend mode
			bMap.blendMode = "add"
				
			// color transform
			cT = new ColorTransform(1,1,1,.8,0,0,0,0)	
				
			// used to scale
			refM = new Matrix();
				
			// stuff for light box
			lRect = new Rectangle(0,0,0,h)
			lP = new Point()
			
			// add a updateEffect event listener
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		
		// custom text updated
		override protected function textUpdated() {
		
			// compute scaling speed 
			scale = 3
			scaleIncr = -2/(currTransition.duration*0.2)
			
			// compute light glow box speed
			lPos = -100
			lIncr = (w+100)/(currTransition.duration*0.8)
			
			// compute countdown to fade out
			countdown = Math.max(1,int(currTransition.delayFrames-16))
			
			// render colored text
			renderColorItem()
		}
		

		// this will render a colored version of item
		public function renderColorItem() {
		
			// clean up
			bColor.fillRect(box,0)
			
			// some stuff needed
			var r = new Rectangle(0,0,w,1)
			var h:uint = hitR.height
			var h2:uint = h/2
			var ci:uint
			var minI:uint = 0x40
			var maxI:uint = 0xFF-minI
			
			// draw the color mask
			for (var yp:uint=0;yp<h;yp++) {
				r.y = yp
				ci = uint((yp > h2) ? maxI*(h-yp)/h2 : maxI*yp/h2)+minI
				bBuffer.fillRect(r,colorMap[ci])
			}
			
			// clean
			bBuffer2.fillRect(box,0)
			
			// draw item
			bBuffer2.copyPixels(bBuffer,hitR,pt,bDraw,origin)
			
			// add glow, if used
			if (currTransition.glow) {
			
				with (dsF) {
					blurX = blurY = 1
					strength = currTransition.glow/100
					quality = 3
				}
			
			
				bColor.applyFilter(bBuffer2,box,origin,dsF)
			
				with (bF) {
					blurX = blurY = 8
					quality = 3
				}
				
				bColor.applyFilter(bColor,box,origin,bF)
				bColor.paletteMap(bColor,box,origin,null,null,null,colorMap)
			} 
			
			var target:BitmapData
			
			// disable bevel filter for small font sizes
			if (currTransition.size < 25 ) {
				target = bBuffer2
			} else {
				bBuffer.applyFilter(bBuffer2,box,origin,bevF)
				target = bBuffer
			}
			
			// final drawing step
			bColor.draw(target,null,null,currTransition.glow ? "add" : "normal",box,true)
			
		}
		
		// buildColorMap will now also update colored item
		override public function buildColorMap(c = "ocean") {
			super.buildColorMap(c)
			if (ready) renderColorItem()
		}
		
		
		// custom transition update
		override protected function transitionUpdated() {
			
			// set the colortransform with transition value
			cT.alphaMultiplier = currTransition.persistence ? Math.min(95,currTransition.persistence)/100 : 0.8
 			
		}
				
		// here is the magic
		public function updateEffect(e=null) {
			
			// if no item, bye
			if (!ready) return
			
			bData.lock()
			bData.colorTransform(box,cT)
			
			// fade in
			if (scale >= 1) {
				
				// scale item
				refM.createBox(scale,scale,0,int(w*(1-scale)/2),int(h*(1-scale)/2))
					
				// clean
				bBuffer.fillRect(box,0)
			
				// compute colorTransform alpha
				with (cT) {
					var oldVal = alphaMultiplier
					alphaMultiplier = (3-scale)/4
					// draw scaled item
					bBuffer.draw(bColor,refM,cT,null,box,false)
					alphaMultiplier = oldVal
				}
				
				// compute blur amount
				with (bF) {
					blurX = uint(8*scale)*2
					blurY = uint(2*scale)*2
					quality = 1
				}
				
				// apply filter
				bBuffer2.applyFilter(bBuffer,box,origin,bF)
				bData.copyPixels(bBuffer2,box,origin,bMask,origin,true)
				scale += scaleIncr
				
				// clean up
				if (scale < 1) bBuffer.fillRect(box,0)
							
			} else {
				
				// fade out
				if (countdown > 0) {
					// if countdown > 0, draw glow light box
					
					bData.copyPixels(bColor,box,origin,null,null,true)
					bBuffer.colorTransform(box,cT)
					
					if (lPos < w) {
						// starting x 
						lP.x = lRect.x = lPos > 0 ? uint(lPos+.5) : 0 
					
						// box width
						lRect.width = uint(((lPos < 0) ? lPos+lIncr : lIncr) + 0.5)
			
						bBuffer.copyPixels(bColor,lRect,lP,null,null,true)
					}
					
					// set drop shadow filter
					with (dsF) {
						blurX = 32
						blurY = 2
						strength = 2
						quality = 1
					}
					
					
					// apply drop shadow
					bBuffer2.applyFilter(bBuffer,box,origin,dsF)
					// use our colormap
					bBuffer2.paletteMap(bBuffer2,box,origin,null,null,null,colorMap)
					bBuffer2.copyPixels(bBuffer2,box,origin,bColor,origin)
					
					// add the light glow box to drawed item
					bData.draw(bBuffer2,null,null,"add")
					
					if (lPos < w) {
						lPos += lIncr
						// if you want just light glow to repeat, uncomment next line
						//if (lPos >= w) lPos = -1000
						if (lPos >= w) updateText()
					} else {
						countdown--
					} 
				} else {
					// use a fixed fade out value
					cT.alphaMultiplier = 0.8
				}
					
			}
						
			bData.unlock()			
		}
		
	
	}

}
	