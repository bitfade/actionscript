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
	import bitfade.intros.backgrounds.Background
	
	public class Spectrum extends bitfade.intros.backgrounds.Background {
		
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
		
		// geom stuff
		protected var box:Rectangle
		protected var cBox:Rectangle	
		protected var pt:Point
		
		// blur filter
		protected var bF:BlurFilter
		
		// color transform used to fade out
		protected var cF:ColorTransform
		
		// some counters
		protected var angleOffset:Number = 0
		protected var globalAngle:Number = 0;		
		protected var colorMix:Number = 0;
		protected var currentPalette:uint = 0;
		protected var countDown:uint = 25
		
		protected var computeLoop:RunNode
		
		// constructor
		public function Spectrum(...args) {
			configure.apply(null,args)
		}
		
		// init the spectrum
		override protected function init():void {
		
			// create the bitmap
			bMap = new Bitmap()
			addChild(bMap)
			
			// bMask / bAlpha are used do draw dots
			bMask = new BitmapData(6,6,true,0xFF << 24)
			bAlpha = bMask.clone()
			
			// copy rectangle (5x5)
			cBox = new Rectangle(0,0,6,6)
			
			colorMap = colorMapTo = colorMapFrom = Colors.buildColorMap("fireHL",0xFF,true)
			
			// create color transform and drop shadow filter 
			cF = new ColorTransform(1,1,1,0.95,0,0,0,0)
			bF = new BlurFilter(4,4,1)
			
			// create bitmaps
			bData = new BitmapData(w,h,true,0)
			bBuffer = bData.clone()
			bBuffer2 = bData.clone()
			
			box = bData.rect
			
			bMap.bitmapData = bData
			
		}
		
		override public function start():void {
			// add the event listener
			computeLoop = Run.every(Run.FRAME,computeSpectrum)
		}
		
		
		override public function gradient(scheme:String = null,immediate:Boolean = false) {
			if (!scheme) scheme = "oceanHL"
			colorMapTo =  Colors.buildColorMap(scheme,0xFF,true)
			colorMix = 0
			if (immediate) {
				colorMapFrom = colorMapTo
			}
		}
		
		override public function burst(...args):void {
			cF.alphaOffset = 0x40
			bBuffer2.colorTransform(box,cF)
			cF.alphaOffset = 0
			
		}
		
		// this will draw the spectrum
		protected function computeSpectrum():void {
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
			
			// scale previously drawed frame
			var scale:Number = 1 + Math.min(Math.max(power/30,0.02),0.2)
			
			bBuffer.fillRect(box,0)
			
			var scaleX:Number = 1 + Math.min(Math.max(power/30,0.01),0.1)
			
			bBuffer.draw(bBuffer2,Geom.createBox(scaleX,scale,0,int(w*(1-scaleX)/2),int((h)*(1-scale)/2)),cF)
			
			if (power > 0) {
				// we have sound
				
				// increase color transition 
				if (colorMapFrom != colorMapTo) {
					colorMix += 1 
				
					if (colorMix > 20) {
						// set a new gradient
						colorMapFrom = colorMapTo
						colorMix = 0
					} else {
						// mix previous and current gradient
						Colors.mix(colorMapFrom,colorMapTo,colorMap,colorMix*5)
					}
					
					
				}
				
 				var pt = new Point()
				
				angleOffset += 0.05*power
				
				// compute global angle and center coordinates
				globalAngle += Math.PI*2*power/256
				
				var rx:Number = 0
				var ry:Number = 0
				var w2:Number = w/2
				var h2:Number = h/2-3
				
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
					
					//pt.x = i*w*4/256
					pt.x = uint(w2+Math.cos(rotAngle)*w)
					pt.y = uint(h2+Math.random()*8-4)
					
					// draw the point
					bMask.fillRect(cBox,alpha)
					bBuffer.copyPixels(bAlpha,cBox,pt,bMask,Geom.origin,true)
					
				}
			
			}
			
			
			bBuffer2.applyFilter(bBuffer,box,Geom.origin,new BlurFilter(4,4,1))
			bData.paletteMap(bBuffer2,box,Geom.origin,null,null,null,colorMap)
			
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			bBuffer = Gc.destroy(bBuffer)
			bBuffer2 = Gc.destroy(bBuffer)
			super.destroy()
		}
				
	}
}
/* commentsOK */