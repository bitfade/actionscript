/*

	Pure actionscript 3.0 light glows text/logo effect with xml based configuration.
	this extends bitfade.text.effect which has common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.transitions.simple
	import bitfade.objects.light.glow
	
	public class lightglows extends bitfade.text.effect {

		// some more bitmapDatas
		protected var bColor:BitmapData;
		protected var bColorOld:BitmapData;
		protected var bBuffer2:BitmapData;
		protected var bDark:BitmapData;
		protected var bMask:BitmapData;
		
		// stuff needed for light glows
		protected var bGlow:BitmapData;
		protected var bGlowFullPower:BitmapData;
		protected var bGlows:BitmapData;
		protected var glows:Array;
		protected var gP:Point;
		
		// transition manager
		protected var transition: bitfade.transitions.simple
		
		// drop shadow filter
		protected var dsF:DropShadowFilter
		
		// color transform used to fade glows
		protected var fadeCT:ColorTransform
		
		// effect status codes
		public static const FADE_IN:uint = 0
		public static const EFFECT:uint = 1
		public static const WAIT:uint = 2
		public static const FADE_OUT:uint = 3
		
		// status
		protected var status:uint = FADE_IN
		
		// use default constructor
		public function lightglows(conf=null) {
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
				type: "slideBottom",
				
				glowVisible: true,
				glowMode: "random",
				
				darkMode: "full",
				darkIntensity: 100,
				
				vMask: 0,
				hMask: 0,
				
				glowMax: 1, 
				glowSpeedMin: 3,
				glowSpeedMax: 5,
				glowIntensity: 3
				
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
			dsF = filter.DropShadowFilter(0,0,0,1,4,4,3,1,false,false,true)
			
			
			// create bitmapdatas
			bColor = bData.clone()
			bColorOld = bData.clone()
			bBuffer2 = bData.clone()
			bDark = bData.clone()
			
			// create stuff for light glows
			bGlows = bData.clone()
			bGlow = bitfade.objects.light.glow.build(Math.min(w,h))
			bGlowFullPower = bGlow.clone()
			glows = new Array(20)
			gP = new Point()
			
					
			// create transition manager
			transition = new simple(bBuffer2,bBuffer)
			transition.crossFade = true
			
			// create colorTransform used to fade glows
			fadeCT = new ColorTransform(1,1,1,0,0,0,0,0)
					
			// use "normal" blend mode
			bMap.blendMode="normal"
			
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
			dsF.strength = currTransition.glowIntensity
			
			// deal with mask settings
			if (currTransition.vMask > 0 || currTransition.hMask > 0) {
				currTransition.useMask = true
				// rebuild mask
				buildMask()
			} else {
				currTransition.useMask = false
			}
			
			// set glows to full power
			setGlowsPower(100)
			
		}
		
		// buildColorMap will now also update colored item
		override public function buildColorMap(c = "oceanHL") {
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
		
		// set glows power
		protected function setGlowsPower(amount:Number = 100) {
			bGlow.copyPixels(bGlowFullPower,bGlowFullPower.rect,origin)
			fadeCT.alphaMultiplier = amount/100
			bGlow.colorTransform(bGlow.rect,fadeCT)
		}
		
		// update light glows
		protected function updateGlows() {
			
			// local variables
			var g:Object, idx:uint = 0, gSize:uint = bGlow.rect.width, 
				gMax:uint, vMin:int, vMult:int, xMin:int, xMult:int, yMin:int, yMult:int
			
			// set local variables
			with (currTransition) {
				gMax = glowMax
				vMin = glowSpeedMin
				vMult = glowSpeedMax - glowSpeedMin 
			}
			
			bGlows.fillRect(box,0)
			
			if (currTransition.glowMode == "fade") {
			
				// "fade" mode, so adjust glow power
				setGlowsPower(((counter < counterMax/2) ? counter/counterMax : (counterMax-counter)/counterMax)*100)
				
				
				xMin = pt.x-bGlow.rect.width/2
				yMin = pt.y-bGlow.rect.height/3
				
				// first glow position
				gP.x = int(Sine.InOut(counter,xMin,hitR.width,counterMax))
				gP.y = yMin
				
				// draw glow
				bGlows.copyPixels(bGlow,bGlow.rect,gP,null,null,true)
					
				// second glow position
				gP.x = (w-bGlow.rect.width) - gP.x
				gP.y = (h-bGlow.rect.height) - yMin
				
				// draw glow
				bGlows.copyPixels(bGlow,bGlow.rect,gP,null,null,true)
				
				
			} else {
			
				// "random" mode, build some min/max ranges
				
				xMin = pt.x-bGlow.rect.width/2
				xMult = hitR.width
			
				yMin = pt.y-bGlow.rect.height/2
				yMult = hitR.height
		
				// create defined number of random moving light glows
				for (idx=0;idx<gMax;idx++) {
					g = glows[idx]
				
					if (!g) {
						glows[idx] = {
							// start position
							sx : Math.random()*xMult+xMin,
							sy : Math.random()*yMult+yMin,
							// end position
							ex : Math.random()*xMult+xMin,
							ey : Math.random()*yMult+yMin,
							// speed
							v : Math.random()*vMult+vMin,
							t : 0
						}
						g = glows[idx]
					}
				
					with (g) {
						// get current glow poisition
						gP.x = int(Cubic.InOut(t,sx,(ex-sx),100))
						gP.y = int(Cubic.InOut(t,sy,(ey-sy),100))
						
						t += v
						
						// draw it
						bGlows.copyPixels(bGlow,bGlow.rect,gP,null,null,true)
					
						// compute opposite position
						gP.x = (w-bGlow.rect.width) - gP.x
						gP.y = (h-bGlow.rect.height) - gP.y
						
						// draw opposite glow
						bGlows.copyPixels(bGlow,bGlow.rect,gP,null,null,true)
					
						// if time reach max, set another random position
						if (t >= 100) {
							t = 0
							sx = ex
							sy = ey
							ex = Math.random()*xMult+xMin
							ey = Math.random()*yMult+yMin
							v = Math.random()*vMult+vMin
						}
					}
				
				}
			
			}
			
		}
		
		// here is the magic
		public function updateEffect(e=null) {
			
			if (!ready) return
			
			// lock main bitmap
			bData.lock()
			
			switch (status) {
				case FADE_IN:
					// do nothing here for now, just jump to EFFECT
					resetCounter(currTransition.duration)
					status = EFFECT
					updateEffect()
				break
				case EFFECT:
				case WAIT:
				 
				 	// darkAlpha is alpha value item not hit with light
				 	var darkAlpha = 0xFF*currTransition.darkIntensity/100
				 	var bItem:BitmapData;
					var tMax:uint = counterMax
					
				 	
				 	// set values according to darkMode
				 	switch (currTransition.darkMode) {
				 		case "full":
				 			if (currTransition.glowMode == "fade") {
					 			tMax = currTransition.darkIntensity > 0 ? uint(counterMax/4) : 0
				 			}
				 		break;
						case "fade":
							tMax = 0
							darkAlpha *= ((counter < counterMax/2) ? counter/counterMax : (counterMax-counter)/counterMax)
						break
						case "reveal":
							tMax = 0
							darkAlpha *= counter/counterMax
						break
					}
					
					// convert to int
					darkAlpha = uint(darkAlpha)
					
					
					if (counter < tMax) {
						// update transition from old item to new one
						transition[currTransition.type](bColorOld,bColor,counter,tMax)
						bItem = bBuffer2
					} else {
						// transition ended, use new item
						bItem = bColor
					}
					
					// clear 
					bData.fillRect(box,0)
					
					// increment light glow power from 0, only if first run
					if (status == EFFECT && conf.firstRun && currTransition.glowMode == "random" ) {
						setGlowsPower(100*counter/counterMax)
					}
					
					// update glows
					updateGlows()
					
					if (currTransition.glowVisible) {
						// visible glow
						bData.copyPixels(bItem,box,origin,bGlows,origin,true)
						bBuffer.applyFilter(bData,box,origin,dsF)
						bBuffer.copyPixels(bGlows,box,origin,null,null,true)
					} else {
						// hidden glow
						bData.copyPixels(bGlows,box,origin,bItem,origin,true)
						bBuffer.applyFilter(bData,box,origin,dsF)
						bBuffer.copyPixels(bData,box,origin,null,null,true)
					}
					
					// use our color gradient
					bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
					
					
					if (darkAlpha > 0) {
						if (darkAlpha < 0xFF) {
							// need to show dark item
							bDark.fillRect(box,darkAlpha << 24)
							bData.copyPixels(bItem,box,origin,bDark,origin)
						} else {
							// dark item is full visible
							bData.copyPixels(bItem,box,origin)
						}
					}
					
					if (darkAlpha < 0xFF) {
						// show light item (if dark not fully visible)
						bData.copyPixels(bItem,box,origin,bBuffer,origin,true)
					} 
					
					// fade out old item in case of "reveal" dark mode
					if (currTransition.darkMode == "reveal" && conf.firstRun == false && counter < 10) {
						bDark.fillRect(box,uint(0xFF*(10-counter)/10*currTransition.darkIntensity/100) << 24)
						bData.copyPixels(bColorOld,box,origin,bDark,origin,true)
						
					}		
					
					// add the glow
					bData.draw(bBuffer,null,null,"add")
					
					
					if (status == EFFECT) {
						if (counter < counterMax) {
							counter++
						} else {
							// transition ended, go to new item
							status = WAIT
							updateText()
						}

					}
				break
				case FADE_OUT:
					// light off glows
					setGlowsPower(100*counter/counterMax)
					updateGlows()
					bData.paletteMap(bGlows,box,origin,null,null,null,colorMap)
					if (counter < counterMax) {
						counter++
					} else {
						// fade status ended, destroy
						destroy()
					}
				break
			}
			
			// use the alpha mask if needed
			if (currTransition.useMask) bData.copyPixels(bData,box,origin,bMask,origin)
			bData.unlock()	
			
			
		}
		
		
	
	}

}
	