/*

	Pure actionscript 3.0 steel melting effect with xml based configuration.
	this extends bitfade.text.particles which has common particles functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	public class steel extends bitfade.text.particles {

		// some other bitmaps
		protected var bColor:BitmapData;
		protected var bBuffer2:BitmapData;
		protected var bMask:BitmapData;
		
		// light box variables
		protected var lPos:Number;
		protected var lIncr:Number;
		protected var lMin:Number;
		protected var lMax:Number;
		protected var lRect:Rectangle;
		protected var lP:Point
		
		// some counters 
		protected var countdown:uint = 0;
		protected var pStart:uint = 0;
		
		// drop shadow filter
		protected var dsF;
		
		// bevel filter
		protected var bevF;
		
		// color trasform used to fade out
		protected var fadeCT:ColorTransform
		
		// use default constructor
		public function steel(conf) {
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
			
			bMap.blendMode = "add"
			
			// create drop shadow filter
			dsF = new DropShadowFilter(0,0,0,1,8,8,3,2,false,false,true)
			// create the bevel filter
			bevF = new BevelFilter(1,45,0xFFFFFF,1,0,1,1,1,1,3,"inner",false)
				
			// stuff for light box
			lRect = new Rectangle(0,0,0,h)
			lP = new Point()
				
			// fade out cT
			fadeCT = new ColorTransform(1,1,1,0.8,0,0,0,0)
				
			// add a updateEffect event listener
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		// custom drawing function
		override protected function draw(data=null) {
			
			// modify the drawing color transform in case of disabled steel effect
			with (drawCT) {
				redMultiplier = greenMultiplier = blueMultiplier = (currTransition.nosteel == "true") ? 1 : 0
			}
			
			super.draw(data)
		}
		
		// this will render a colored version of item
		public function renderColorItem() {
		
			// clean up
			bColor.fillRect(box,0)
			
			if (currTransition.nosteel == "true") {
				bColor.copyPixels(bDraw,hitR,pt)
				return
			}
			
			// use noise + blur for steel effect
			bBuffer2.noise(1,0,0xFF,7, true)
			bBuffer.applyFilter(bBuffer2,box,origin,new BlurFilter(64,2,2))
			
			// draw item (1st pass)
			bBuffer2.fillRect(box,0)
			bBuffer2.copyPixels(bBuffer,hitR,pt,bDraw,origin)
			
			// some stuff needed
			var hh:uint = hitR.height 
			var r = new Rectangle(0,0,w,1)
			var minI:uint = 0
			var maxI:uint = 0xFF
			var I:Number = minI
			var iI:uint = 0
			var step:Number = 4*(maxI - minI)/hh
			
			// draw the color mask
			for (var yp:uint=0;yp<hh;yp++) {
				r.y = yp
				I += step
				if (I > maxI) {
					I = maxI
					step = -Math.abs(step)
				} else if (I < minI) {
					I = minI
					step = Math.abs(step)
				} 
				iI = uint(I)
				bMask.fillRect(r,0xFF000000 + (iI << 16) + (iI << 8) + iI)
				
			}
			
			// draw item (2nd pass) - add the color mask
			bBuffer.fillRect(box,0)
			bBuffer.copyPixels(bMask,hitR,pt,bDraw,origin)
			bBuffer2.draw(bBuffer,null,null,"lighten")
			
			
			var target:BitmapData
			
			// disable bevel filter for small font sizes
			if (currTransition.size < 25 ) {
				target = bBuffer2
			} else {
				bBuffer.applyFilter(bBuffer2,box,origin,bevF)
				target = bBuffer
			}
			// final drawing step
			bColor.copyPixels(target,box,origin)
			
		}
		
		// custom text updated
		override protected function textUpdated() {
			// let's compute some timings to respect transition duration
			lPos = pt.x
			lIncr = (hitR.width)/(currTransition.duration)
			lMax = hitR.width+pt.x
			countdown = Math.max(1,int(currTransition.delayFrames-16))
			
			
			// render colored text
			renderColorItem()
			
			// reset particles
			bPart.fillRect(box,0)
			for (var pIdx:uint=0;pIdx<maxParticles;pIdx++) pl[pIdx] = 0
			
		}
	
		// buildColorMap will now also update colored item
		override public function buildColorMap(c = "fire") {
			super.buildColorMap(c)
			if (ready) renderColorItem()
		}
		
		// add particles
		protected function addParticles(xstart:uint,xe:uint) {
		
			var xp:uint
			var yp:uint
			
			// starting x,y
			var xs:uint = pt.x
			var ys:uint = pt.y
			
			var xt:uint
			var yt:uint
			
			// ending x,y
			var ye:uint = hitR.height
			
			var pIdx:uint = pStart
			
			var r = new Rectangle(0,0,2,2)
			
			// stuff needed for XorShift random generator
			var vxMin:Number = -1
			var vxMult:Number = 4/0xFFFF
			
			var vyMin:Number = -2
			var vyMult:Number = 4/0xFFFF
			
			var vlMin:Number = 4
			var vlMult:Number = 16/0xFFFF
			
			// analyze item for alpha>0 2x2 rectangles
			for (xp=xstart;xp<xe;xp += 2) {
				r.x = xp
				xt = xs+xp
				for (yp=0;yp<ye;yp += 2) {
					r.y = yp
					
					if (bDraw.hitTest(origin,0x01,r)) {
						// yeah! just found one
						yt = ys+yp	
						
						pl[pIdx] = maxLife
						px[pIdx] = xt
						py[pIdx] = yt
							
						// velocity
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						pvl[pIdx] = (rndW & 0xFFFF)*vlMult+vlMin
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						pvx[pIdx] = (rndW & 0xFFFF)*vxMult+vxMin
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						pvy[pIdx] = (rndW & 0xFFFF)*vyMult+vyMin
						pay[pIdx] = 0.2
														
						// mode 0 = from 0 to max light
						pm[pIdx] = 0
						
						pIdx ++
						// take care of maxParticles
						if (pIdx > maxParticles) pIdx = 0
					}
				}
			}
			pStart = pIdx
			activeParticles = 1
		}
		
		// custom transition update
		override protected function transitionUpdated() {	
			// set the colortransform with transition value
			cT.alphaMultiplier = currTransition.persistence ? Math.min(95,currTransition.persistence)/100 : 0.3
		}
				
		// here is the magic
		public function updateEffect(e=null) {
			
			// if no item, bye
			if (!ready) return
			
			bData.lock()
			
			// melt mode
			if (countdown > 0) {
			
				// clean up
				bData.fillRect(box,0)
				
				// starting pos
				lP.x = lP.y = lRect.x = 0 
				// box width
				lRect.width = uint(lPos + 0.5)
			
				// copy item (part)
				bData.copyPixels(bColor,lRect,lP,null,null,true)
			
				// add particles
				addParticles(lPos-pt.x,lPos-pt.x+1)
				renderParticles()
			
				lRect.x = lPos-pt.x
				lRect.width = 8
				lP.x = lPos
				lP.y = pt.y
				
				
				// copy small amount of particles and item
				bBuffer2.fillRect(box,0)
				bBuffer2.copyPixels(bDraw,lRect,lP,null,null,true)
				bBuffer2.copyPixels(bPart,box,origin,bBuffer2,origin,true)
			
				// add a random glow
				with (dsF) {
					blurX = blurY = uint(Math.random()*8+4.5)*2
				}
			
				bBuffer.applyFilter(bBuffer2,box,origin,dsF)
				
				// add particles
				bBuffer.copyPixels(bPart,box,origin,null,null,true)
				
				// use our colormap
				bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
				bData.draw(bBuffer,null,null,"add")
			
				if (lPos < lMax) {
					lPos += lIncr
					// transition end, go to next
					if (lPos >= lMax) updateText()
				} else {
					// fade out delay
					countdown--
				}
			} else {
				// fade out code
				bData.colorTransform(box,fadeCT)
			}
			
			bData.unlock()
			
		}
		
	
	}

}
	