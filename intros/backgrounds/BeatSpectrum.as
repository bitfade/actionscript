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
	
	public class BeatSpectrum extends bitfade.intros.backgrounds.Background {
		
		protected var computeLoop:RunNode
		
		protected var power:uint = 0
		
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
		
		// constructor
		public function BeatSpectrum(...args) {
			configure.apply(null,args)
		}
		
 
		// init the spectrum
		override protected function init():void {
			
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
			
			// create bitmaps
			bData = new BitmapData(w,h,true,0)
			bBuffer = bData.clone()
			bBuffer2 = bData.clone()
			
			box = bData.rect
			
			bMap.bitmapData = bData
		
			// bMask / bAlpha are used do draw dots
			bMask = new BitmapData(5,5,true,0xFF << 24)
			bAlpha = bMask.clone()
			
			// copy rectangle (5x5)
			cBox = new Rectangle(0,0,5,5)
			
			// get some color schemes, we'll cycle from one to other
			colorPalettes = new Array()
			for each (var scheme in ["fireHL","purpleHL","oceanHL","limeHL"]) {
				colorPalettes.push(Colors.buildColorMap(scheme,0xFF,true))
			}
			colorMap = new Array(256)
			colorMapTo = colorMapFrom = colorPalettes[0]
			
			// create color transform and drop shadow filter 
			cF = new ColorTransform(1,1,1,0.95,0,0,0,0)
			dsF = new DropShadowFilter(0,0,0,1,8,8,1,1,false,false,true)

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
			var power:Number = Beat.detect().power
			power = 0.3*power
			
			if (power > 0) {
				// if no sound, start the countdown to deactivate
				countDown = 50;
			} else {
				if (countDown == 0) return
				countDown--
			}
			
			// get levels and freqs from spectrum
			/*
			var levels:Array = bitfade.utils.sound.levels
			var freqs:Array = bitfade.utils.sound.freqs
			var activeFreqs:uint = bitfade.utils.sound.activeFreqs
			*/
			var i:uint
			
			// scale previously drawed frame
			power += 0.01*countDown
			
			var scale:Number = 1 + Math.min(Math.max(power/30,0.02),0.2)
			scale = 1.03
			bBuffer.fillRect(box,0)
			bBuffer.draw(bBuffer2,Geom.createBox(scale,scale,0,int(w*(1-scale)/2),int(h*(1-scale)/2)),cF)
			
			
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
				var rx:Number = Math.cos(globalAngle)*w/16
				var ry:Number = Math.sin(globalAngle*0.9)*h/16
				var w2:Number = w/2
				var h2:Number = h/2
				
				// angle used to draw the circles
				var angle:Number = 0
				var angleIncr:Number = Math.PI*2/256
				
				// some variables needed later
				var cf:Number
				var powerFactor:Number = Math.min(70,30+5*power)
				//trace(powerFactor)
				var radius:Number
				var alpha:uint
				var computedCos:Number
				var computedSin:Number
				var rotAngle:Number = 0
				
				// for each freq (0-255), draw dot
				for (i=0;i<256;i++,angle += angleIncr) {
					cf = beats[i]
					
					// if freq vale is 0, no nothing
					if (cf == 0) continue
					
					// compute angle and radius
					rotAngle = angle + angleOffset
					//radius = powerFactor-freqs[i % 6]*20
					radius = powerFactor
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
			
			
			dsF.strength = Math.min(1,Math.max(Math.max(power/3),0.5))
			dsF.strength = 1
			
			bBuffer2.applyFilter(bBuffer,box,Geom.origin,dsF)
			bData.paletteMap(bBuffer2,box,Geom.origin,null,null,null,colorMap)			
			
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */