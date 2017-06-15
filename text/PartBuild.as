/*

	Pure actionscript 3.0 light particles build effect with xml based configuration.
	this extends bitfade.text.particles which has common particles functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	public class partBuild extends bitfade.text.particles {

		protected var countdown:uint = 0;
		protected var pStart:uint = 0;
		
		// some other bitmaps
		protected var bColor:BitmapData;
		protected var bBuffer2:BitmapData;
		
		// speed of particles when build item
		protected var buildPartSpeed:Number
		
		// speed of particles when fade out
		protected var fadeOutPartSpeed:Number
		
		// drop shadow filter
		private var dsF;

		// use default constructor
		public function partBuild(conf) {
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
			
			bMap.blendMode = "add"
			
			// create drop shadow filter
			dsF = new DropShadowFilter(0,0,0,1,8,8,2,2,false,false,true)
				
			// add a updateEffect event listener
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		
		// custom text updated
		override protected function textUpdated() {
		
			// let's compute some timings to respect transition duration
			buildPartSpeed = 21*stage.frameRate/(currTransition.duration*0.4)
			fadeOutPartSpeed = 21*stage.frameRate/(currTransition.duration*0.2)
			countdown = uint(currTransition.duration*0.4)
			
			
			// render colored text
			renderColorItem()
			
			// clear some things
			bBuffer.fillRect(box,0)
			bBuffer2.fillRect(box,0)
			
			// reset particles
			bPart.fillRect(box,0)
			for (var pIdx:uint=0;pIdx<maxParticles;pIdx++) pl[pIdx] = 0
			
			// add particles
			addParticles(0,hitR.width,false)
		}
		

		// this will render a colored version of item
		public function renderColorItem() {
		
			bBuffer.fillRect(box,0x80FFFFFF)
			bColor.fillRect(box,0)
			bBuffer2.fillRect(box,0)
			
			bColor.copyPixels(bBuffer,box,pt,bDraw,origin)
			
			bBuffer.fillRect(box,0)
			bBuffer.applyFilter(bDraw,hitR,pt,new DropShadowFilter(0,0,0,1,4,4,1,3,false,false,true))
			
			
			bBuffer2.applyFilter(bDraw,hitR,pt,new BlurFilter(32,4,3))
			bBuffer.copyPixels(bBuffer2,box,origin,null,null,true)
			bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			bColor.draw(bBuffer,null,null,"add")
			
		}
		
		// buildColorMap will now also update colored item
		override public function buildColorMap(c = "ocean") {
			super.buildColorMap(c)
			if (ready) renderColorItem()
		}
		
		// add particles
		protected function addParticles(xstart:uint,xe:uint,out=true) {
		
			var xp:uint
			var yp:uint
			
			// starting x,y
			var xs:uint = pt.x
			var ys:uint = pt.y
			
			var xt:uint
			var yt:uint
			
			// ending x,y
			var ye:uint = hitR.height
			
			// center
			var xc:uint = w/2
			var yc:uint = h/2
			
			var pIdx:uint = pStart
			
			var r = new Rectangle(0,0,2,2)
			
			// stuff needed for XorShift random generator
			var xMin = 0
			var xMult = (w-xMin)/0xFFFF
			
			var yMin = 0
			var yMult = (h-yMin)/0xFFFF
			
			var lMin = maxLife/2
			var lMult = (maxLife-lMin)/0xFFFF
			
			// analyze item for alpha>0 2x2 rectangles
			for (xp=xstart;xp<xe;xp += 2) {
				r.x = xp
				xt = xs+xp
				for (yp=0;yp<ye;yp += 2) {
					r.y = yp
					
					if (bDraw.hitTest(origin,0x01,r)) {
						// yeah! just found one
						yt = ys+yp	
						
						// fade out ?
						if (out) {
							// start life/position 
							rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
							pl[pIdx] = (rndW & 0xFFFF)*lMult+lMin
							px[pIdx] = xt
							py[pIdx] = yt
							
							// velocity
							pvl[pIdx]=fadeOutPartSpeed							
							pvx[pIdx] = pvl[pIdx]*(xt-xc)/pl[pIdx]
							pvy[pIdx] = pvl[pIdx]*(yt-yc)/pl[pIdx]
														
							// mode 0 = from 0 to max light
							pm[pIdx] = 0
						} else {
							// start life/position 
							pl[pIdx] = maxLife
							rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
							px[pIdx] = (rndW & 0xFFFF)*xMult+xMin
							rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
							py[pIdx] = (rndW & 0xFFFF)*yMult+yMin
							
							// velocity
							pvl[pIdx] = buildPartSpeed
							pvx[pIdx] = buildPartSpeed*(xt-px[pIdx])/maxLife
							pvy[pIdx] = buildPartSpeed*(yt-py[pIdx])/maxLife
							
							// mode 1 = from max light to 0
							pm[pIdx] = 1
						}
						
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
			cT.alphaMultiplier = currTransition.persistence ? Math.min(95,currTransition.persistence)/100 : 0.8
 			
		}
				
		// here is the magic
		public function updateEffect(e=null) {
			
			// if no item, bye
			if (!ready) return
			
			bData.lock()
			
			// clean up
			bData.fillRect(box,0)
			
			
			if (countdown > 1) {
				// particles build mode
				
				// do we have particles ?
				if (activeParticles > 0) {
					// yes, render 
					renderParticles()
					
					bBuffer.fillRect(box,0)
					
					// add item shape
					bBuffer.copyPixels(bDraw,hitR,origin,bPart,pt,true)
					bBuffer2.applyFilter(bBuffer,hitR,pt,dsF)
					
					// apply colormap
					bData.copyPixels(bPart,box,origin,null,null,true)
					bData.copyPixels(bBuffer2,box,origin,null,null,true)
					bData.paletteMap(bData,box,origin,null,null,null,colorMap)
					
					// save last step
					if (activeParticles == 0) {
						bBuffer.copyPixels(bPart,box,origin)
						bBuffer.copyPixels(bBuffer2,box,origin,null,null,true)
					}
				} else {
					// no particles left, fade out last step
					bBuffer.colorTransform(box,cT)
					bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
					bData.draw(bColor,null,null,"hardlight")
					// countdown
					countdown--
				
				}
				
				
			} else {
				// fade out = explosion mode
				if (countdown == 1) {
					// add particles
					addParticles(0,hitR.width,true)
					// switch to last step
					countdown = 0
				} else {
					// last step
					if (activeParticles > 0) {
						// we have particles, render
						renderParticles()
						bData.paletteMap(bPart,box,origin,null,null,null,colorMap)
					} else {
						// ok, no more left = we are done here
						updateText()
					}
				}
			}
			
			bData.unlock()
			
		}
		
	
	}

}
	