/*

	Pure actionscript 3.0 jet fire text/logo effect with xml based configuration.
	this extends bitfade.text.effect which has common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	import bitfade.utils.*
	import bitfade.transitions.simple
	
	public class jetfire extends bitfade.text.effect {

		// holds jet beams
		protected var jetBeams:Array
		
		// some more bitmapDatas
		protected var bColor:BitmapData;
		protected var bColorOld:BitmapData;
		protected var bBuffer2:BitmapData;
		protected var bReactor:BitmapData;
		protected var bBeam:BitmapData;
		protected var bMask:BitmapData;
		
		// transition manager
		protected var transition: bitfade.transitions.simple
		
		// drop shadow filter
		protected var dsF:DropShadowFilter
		
		// color transform used to fade effect
		protected var fadeCT:ColorTransform
		
		// effect status codes
		public static const FADE_IN:uint = 0
		public static const EFFECT:uint = 1
		public static const WAIT:uint = 2
		public static const FADE_OUT:uint = 3
		
		// status
		protected var status:uint = FADE_IN
		
		// use default constructor
		public function jetfire(conf=null) {
			super(conf)
		}
		
		// this override default settings defined in parent
		override protected function setDefaults() {
			// global settings
			misc.setDefaults(defaults.conf,{ 
				fade: 1 
			})
			
			// transition settings, look in help for a complete description
			defaults.transition = {
				type: "slideRight",
				mode: "add",
				vMask: 0,
				hMask: 0,
				intensity: 0.8,
				persistence: 88,
				
				jetMax: 50, 
				jetSize: 32,
				jetSpeedMin: 40,
				jetSpeedMax: 80,
				jetIntensity: 6,
				jetRandomY : true
			}
			// transition timings
			defaults.timings = {
				duration:1,
				delay:3
			}
			// item settings
			defaults.item = {
				forceBlack:false,
				effect: true
			}				
		}
		
		
		// destructor
		override protected function destroy() {
			if (status != FADE_OUT) {
				resetCounter(conf.fade)
				status = FADE_OUT
			} else {
				removeEventListener(Event.ENTER_FRAME,updateEffect)
				super.destroy()
			}
		}
		
		// custom init
		override protected function customInit() {
			
			// convert from seconds to frames
			conf.fade *= stage.frameRate
			
			// create the filter
			dsF = filter.DropShadowFilter(0,0,0,1,32,32,0.7,1,false,false,true)
			
			// create bitmapdatas
			bColor = bData.clone()
			bColorOld = bData.clone()
			bBuffer2 = bData.clone()
			bReactor = bData.clone();
			bBeam = bData.clone()
					
			// create transition manager
			transition = new simple(bBuffer2,bBuffer)
			transition.crossFade = true
			
			// create colorTransform used to fade out jet
			fadeCT = new ColorTransform(1,1,1,0.88,0,0,0,0)
					
			// use "normal" blend mode
			bMap.blendMode="normal"
			
			// create array holdings jet beams (200 = max)
			jetBeams = new Array(200)
			
			// set status and reset counter
			status = FADE_IN
			resetCounter(conf.fade)
			
			// effect updater
			addEventListener(Event.ENTER_FRAME,updateEffect)
		}
		
		// build alpha mask
		protected function buildMask() {
		
			// if first invocation, create the bitmapData
			if (!bMask) bMask = bData.clone()
			
			// create a shape
			var sh:Shape = new Shape()
			var mw:uint = currTransition.hMask
			var mh:uint = currTransition.vMask
			
			// draw a rectangle
			with (sh.graphics) {
				beginFill(0,1)
				drawRoundRect(mw,mh,w-mw*2,h-mh*2,64,64)
			}
			
			// convert to bitmapData and blur it
			with (bMask) {
				fillRect(box,0)
				draw(sh)
				applyFilter(bMask,box,origin,filter.BlurFilter(mw,mh,2))
			}
		}
		
		// build a single beam 
		protected function buildJetBeam() {
			
			var size:uint = currTransition.jetSize
			var blurY:uint = size > 8 ? uint(size/8) : 0
			
			// draw the beam and apply a blur filter
			with (bBeam) {
				fillRect(box,0)
				fillRect(new Rectangle(64,blurY,w-128,size-blurY*2),uint(currTransition.jetIntensity*0xFF/100) << 24)
				applyFilter(bBeam,box,origin,filter.BlurFilter(64,blurY,2))
			}
		
		}
		
		
		// custom drawing function
		override protected function draw(data=null) {
			
			// modify the drawing color transform in case of use of forceBlack
			with (drawCT) {
				redMultiplier = greenMultiplier = blueMultiplier = currText.forceBlack ? 0 : 1
			}
			
			// call parent
			super.draw(data)
		}
		
		// custom text updated
		override protected function textUpdated()  {
			// draw colored item
			renderColorItem()
			
			if (status != FADE_IN) {
				// reset counter
				resetCounter(currTransition.duration)
				status = EFFECT
			}
			
		}
		
		// custom transition update
		override protected function transitionUpdated() {
			// change filter strength
			dsF.strength = currTransition.intensity
			
			// change persistence
			fadeCT.alphaMultiplier = currTransition.persistence/100
			
			// deal with mask settings
			if (currTransition.vMask > 0 || currTransition.hMask > 0) {
				currTransition.useMask = true
				// rebuild mask
				buildMask()
			} else {
				currTransition.useMask = false
			}
			
			// rebuild beam
			buildJetBeam()
		}
		
		// buildColorMap will now also update colored item
		override public function buildColorMap(c = "fireHL") {
			super.buildColorMap(c)
			if (ready) renderColorItem()
		}
		
		// this will render a colored version of item
		public function renderColorItem() {
		
			// copy old item
			bColorOld.copyPixels(bColor,box,origin)
			
			// clean up
			bColor.fillRect(box,0)
			
			// deal with forceBlack item setting
			if (currText.forceBlack) {
				bBuffer.fillRect(box,0xFF303030)
				bColor.copyPixels(bBuffer,hitR,pt,bDraw,origin)				
			} else {
				bColor.copyPixels(bDraw,hitR,pt)
			}
			
			// save filter state
			filter.push(dsF)
			
			// if effect is enabled for current item, apply some filters	
			if (currText.effect) {
				bBuffer.applyFilter(bColor,box,origin,filter.assign(dsF,4,45,0,1,8,8,2,2,true,false,false))
				bColor.applyFilter(bBuffer,box,origin,filter.assign(dsF,2,225,0,1,16,16,1,2,true,false,false))
				bBuffer.applyFilter(bColor,box,origin,filter.assign(dsF,1,45,0xFFFFFF,1,2,2,1,2,true,false,false))
				bColor.applyFilter(bBuffer,box,origin,filter.GlowFilter(0,1,2,2,1,2,false,false))
			}
			
			// reload filter state
			filter.pop(dsF)
			
			
		}
		
		// update jet reactor
		public function updateReactor() {
		
			// some local used geom stuff
			var dpt:Point = new Point()
			var r:Rectangle = new Rectangle(0,0,w,currTransition.jetSize)
			
			// local variables
			var jet:Object, idx:uint = 0, rh:uint, ry:int, rMax:uint, vMin:uint, vMult:uint, rndY
			
			rh = ready ? hitR.height : h/2
			
			// set local variables
			with (currTransition) {
				ry = (ready ? pt.y : h/4) -(jetSize >> 1)
				rMax = jetMax
				vMin = jetSpeedMin
				vMult = jetSpeedMax - jetSpeedMin 
				rndY = jetRandomY
			}
			
			// fade out reactor
			bReactor.colorTransform(box,fadeCT)
			
			// draw beams
			for (; idx <rMax; idx ++ ) {
			
				jet = jetBeams[idx]
				
				// if no beam or offscreen beam, create it
				if (!jet || jet.x > w) {
					 jet = {
						y:uint(Math.random()*rh+ry),
						x:int(Math.random()*w-2*w),
						vx:uint(Math.random()*vMult+vMin)
					}
					
					jetBeams[idx] = jet
				}
				
				// update position
				jet.x += jet.vx
				
				// add some random Y, if needed
				if (rndY) {
					jet.y += int(Math.random()*16-8+0.5)
				}
				
				// draw the beam
				dpt.x = jet.x
				dpt.y = jet.y
				bReactor.copyPixels(bBeam,r,dpt,null,null,true)
			}
		}
		
		// here is the magic
		public function updateEffect(e=null) {
			
			// update reactor
			updateReactor()
				
			// lock main bitmap
			bData.lock()
			
			switch (status) {
				case FADE_IN:
					
					// if fade status, just draw the faded reactor 
					bBuffer.fillRect(box,uint(0xFF*counter/counterMax) << 24)
					bData.copyPixels(bReactor,box,origin,bBuffer,origin)
					bData.paletteMap(bData,box,origin,null,null,null,colorMap)
					
					if (counter >= counterMax) {
						// fade status ended, reset counter and change status
						resetCounter(currTransition.duration)
						status = EFFECT
					} else {
						counter++
					}
				break
				case EFFECT:
				case WAIT: 
					
					if (!ready) {
						bData.paletteMap(bReactor,box,origin,null,null,null,colorMap)
						break
					}
					
					var bItem:BitmapData;
			
					if (counter < counterMax) {
						// update transition from old item to new one
						transition[currTransition.type](bColorOld,bColor,counter,counterMax)
						bItem = bBuffer2
					} else {
						// transition ended, use new item
						bItem = bColor
					}
			
			
					with (bData) {
						// draw reactor
						bBuffer.copyPixels(bReactor,box,origin,bItem,origin)
						applyFilter(bBuffer,box,origin,dsF)
						copyPixels(bReactor,box,origin,bData,origin,true)
			
						// use our colormap
						bBuffer.paletteMap(bData,box,origin,null,null,null,colorMap)
						paletteMap(bReactor,box,origin,null,null,null,colorMap)
						
						// add the item
						copyPixels(bItem,box,origin,null,null,true)
						
					}
					bData.draw(bBuffer,null,null,currTransition.mode)
					
					if (status == EFFECT) {
						if (counter > counterMax) {
							// transition ended, go to new item
							updateText()
							status = WAIT
						} else {
							counter++
						}

					}
				break
				case FADE_OUT:
					
					// if fade out status, just draw the faded reactor 
					bBuffer.fillRect(box,uint(0xFF*(counterMax-counter)/counterMax) << 24)
					bData.copyPixels(bReactor,box,origin,bBuffer,origin)
					bData.paletteMap(bData,box,origin,null,null,null,colorMap)
					
					if (counter >= counterMax) {
						// fade status ended, destroy
						destroy()
					} else {
						counter++
					}
				break
			}
			
			// use the alpha mask if needed
			if (currTransition.useMask) bData.copyPixels(bData,box,origin,bMask,origin)
			bData.unlock()	
			
			
		}
		
		
	
	}

}
	