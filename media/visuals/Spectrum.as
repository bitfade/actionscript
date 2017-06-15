/*

	This class is used display a spectrum

*/
package bitfade.media.visuals {
	
	import flash.display.*
	import flash.geom.*
	import flash.events.*
	import flash.utils.*
	import flash.media.*
	import flash.filters.*
	
	//import bitfade.media.streams.*
	import bitfade.utils.*
	
	public class Spectrum extends bitfade.media.visuals.Visual {
		
		// bmap holding the spectrum
		protected var bMap:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bBuffer:BitmapData
		protected var bBuffer2:BitmapData
		protected var bMask:BitmapData
		protected var bAlpha:BitmapData
		
		// colormaps used for gradients
		protected var colorMap:Array
		protected var colorMapFrom:Array
		protected var colorMapTo:Array
		protected var colorPalettes:Array
		
		// geom stuff
		protected var box:Rectangle
		protected var cBox:Rectangle	
		protected var pt:Point
		
		// shadow filter
		protected var dsF:DropShadowFilter
		
		// color transform used to fade out
		protected var cF:ColorTransform
		
		// some counters
		protected var angleOffset:Number = 0
		protected var globalAngle:Number = 0;		
		protected var colorMix:Number = 0;
		protected var currentPalette:uint = 0;
		protected var countDown:uint = 25
		
		// black background
		protected var background:Shape;
		
		// constructor
		public function Spectrum(w:uint=0,h:uint=0) {
			super()
			init()
			resize(w,h)
		}
		
		// init the spectrum
		protected function init():void {
		
			background = new Shape();
			addChild(background)
			
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
			
			// add the event listener
			Events.add(this,Event.ENTER_FRAME,computeSpectrum)
			
			// bMask / bAlpha are used do draw dots
			bMask = new BitmapData(5,5,true,0xFF << 24)
			bAlpha = bMask.clone()
			
			// copy rectangle (5x5)
			cBox = new Rectangle(0,0,5,5)
			
			// get some color schemes, we'll cycle from one to other
			colorPalettes = new Array()
			for each (var scheme in ["fireHL","purpleHL","oceanHL","limeHL"]) {
				colorPalettes.push(Colors.buildColorMap(scheme,0xFF,true))
				//colorPalettes.push(colors.buildColorMap(scheme,0xFF,true)
			}
			colorMap = new Array(256)
			colorMapTo = colorMapFrom = colorPalettes[0]
			
			// create color transform and drop shadow filter 
			cF = new ColorTransform(1,1,1,0.95,0,0,0,0)
			dsF = new DropShadowFilter(0,0,0,1,8,8,1,1,false,false,true)
		}
		
		// scale spectrum
		override protected function scale():void {
			// if no size, do nothing
			if (maxW == 0 && maxH == 0) return
			
			background.graphics.beginFill(0,1)
			background.graphics.drawRect(0,0,maxW,maxH)
			background.graphics.endFill()
		
			
			
			// remove previously created bitmaps (if needed)
			if (bData) {
				bData.dispose()
				bBuffer.dispose()
				bBuffer2.dispose()
			}
			
			// create bitmaps
			bData = new BitmapData(maxW,maxH,true,0)
			bBuffer = bData.clone()
			bBuffer2 = bData.clone()
			
			box = bData.rect
			
			bMap.bitmapData = bData
			
		}
		
		// this will draw the spectrum
		protected function computeSpectrum(e:Event):void {
			// bData is not ready ? do nothing
			if (paused || !bData) return
			
			// compute spectrum levels
			bitfade.utils.Sound.computeSpectrum()
			
			// total sounnd power
			var power:Number = bitfade.utils.Sound.power
			
			if (power > 0) {
				// if no sound, start the countdown to deactivate
				countDown = 50;
			} else {
				if (countDown == 0) return
				countDown--
			}
			
			// get levels and freqs from spectrum
			var levels:Array = bitfade.utils.Sound.levels
			var freqs:Array = bitfade.utils.Sound.freqs
			var activeFreqs:uint = bitfade.utils.Sound.activeFreqs
			var i:uint
			
			var multiplier:Number = Math.max(0.5,Math.min(1,(maxW*maxH)/20000))
			
			if (multiplier < 1) {
				power *= multiplier
				activeFreqs *= multiplier
				
				for (i=0;i<levels.length;i++) {
					levels[i] *= multiplier
				}
				
				for (i=0;i<freqs.length;i++) {
					freqs[i] *= multiplier
				}
				
			}
			
			
			// scale previously drawed frame
			var scale:Number = 1 + Math.min(Math.max(power/30,0.02),0.2)
			
			bBuffer.fillRect(box,0)
			bBuffer.draw(bBuffer2,Geom.createBox(scale,scale,0,int(maxW*(1-scale)/2),int(maxH*(1-scale)/2)),cF)
			
			if (power > 0) {
				// we have sound
				
				// increase color transition 
				colorMix += 1 
				
				if (colorMix > 100) {
					// set a new gradient
					colorMapFrom = colorMapTo
					currentPalette = (currentPalette + 1) % colorPalettes.length
					colorMapTo = colorPalettes[currentPalette]
					colorMix = 0
				}
				
				// mix previous and current gradient
				Colors.mix(colorMapFrom,colorMapTo,colorMap,colorMix)
				
				
				var pt = new Point()
				
				angleOffset += 0.05*power
				
				// compute global angle and center coordinates
				globalAngle += Math.PI*2*power/256
				var rx:Number = Math.cos(globalAngle)*maxW/16
				var ry:Number = Math.sin(globalAngle*0.9)*maxH/16
				var w2:Number = maxW/2
				var h2:Number = maxH/2
				
				// angle used to draw the circles
				var angle:Number = 0
				var angleIncr:Number = Math.PI*2/256
				
				// some variables needed later
				var cf:Number
				var powerFactor:Number = 15*power
				var radius:Number
				var alpha:uint
				var computedCos:Number
				var computedSin:Number
				var rotAngle:Number = 0
				
				// for each freq (0-255), draw dot
				for (i=0;i<256;i++,angle += angleIncr) {
					cf = freqs[i]
					
					// if freq vale is 0, no nothing
					if (cf == 0) continue
					
					// compute angle and radius
					rotAngle = angle + angleOffset
					radius = powerFactor-freqs[i % 6]*20
					alpha = uint(cf*0xFF) << 24
					
					// set point coordinates
					pt.x = uint(w2+rx+Math.cos(rotAngle)*radius)
					pt.y = uint(h2+ry+Math.sin(rotAngle)*radius)
					
					// draw the point
					bMask.fillRect(cBox,alpha)
					bBuffer.copyPixels(bAlpha,cBox,pt,bMask,Geom.origin,true)
					
					// second circle, invert rotation
					rotAngle = angle - angleOffset
					
					// set point coordinates
					pt.x = uint(w2-rx+Math.cos(rotAngle)*radius)
					pt.y = uint(h2-ry+Math.sin(rotAngle)*radius)
					
					// draw the point
					bMask.fillRect(cBox,alpha)
					bBuffer.copyPixels(bAlpha,cBox,pt,bMask,Geom.origin,true)
					
				}
			
			}
			
			
			dsF.strength = Math.min(1,Math.max(Math.max(power/3,1-activeFreqs/256),0.5))
			
			bBuffer2.applyFilter(bBuffer,box,Geom.origin,dsF)
			bData.paletteMap(bBuffer2,box,Geom.origin,null,null,null,colorMap)
			
		}
		
		// clean up
		override public function destroy():void {
			bData.dispose()
			bBuffer.dispose()
			bBuffer2.dispose()
			
			super.destroy()
			//removeChild(bMap)
		}
				
	}


}