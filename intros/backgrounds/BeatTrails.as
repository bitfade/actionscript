/*

	Light Trails beat detector intro background

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
	
	public class BeatTrails extends bitfade.intros.backgrounds.Background {
		
		protected var computeLoop:RunNode
		
		protected var power:uint = 0
		
		// bmap holding the spectrum
		protected var bMap:Bitmap
		
		// some other bitmapData needed
		protected var bData:BitmapData
		protected var bBuffer:BitmapData
		protected var bMask:BitmapData
		
		// colormaps used for gradients
		protected var colorMap:Array
		protected var colorMapFrom:Array
		protected var colorMapTo:Array
		protected var colorPalettes:Array
		
		// geom stuff
		protected var box:Rectangle
		protected var pt:Point
		
		// color transform used to fade out
		protected var cF:ColorTransform
		
		// some counters
		protected var angleOffset:Number = 0
		protected var globalAngle:Number = 0;		
		protected var colorMix:Number = 0;
		protected var currentPalette:uint = 0;
		protected var countDown:uint = 25
		
		protected var offset:Number = 0;
		
		// constructor
		public function BeatTrails(...args) {
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
			
			box = bData.rect
			
			bMap.bitmapData = bData
		
			// build alpha mask 
			if (conf && conf.blur) {
				conf.blur = conf.blur.split(/,| /i)
				
				var blurTop:uint = parseInt(conf.blur[0])
				var blurRight:uint = parseInt(conf.blur[1])
				var blurBottom:uint = parseInt(conf.blur[2])
				var blurLeft:uint = parseInt(conf.blur[3])
				
				bMask = bData.clone()
				bMask.fillRect(Geom.rectangle(blurLeft,blurTop,w-blurLeft-blurRight,h-blurTop-blurBottom),0xFF000000)
				bMask.applyFilter(bMask,bMask.rect,Geom.origin,new DropShadowFilter(0,0,0,1,Math.max(blurLeft,blurRight),Math.max(blurTop,blurBottom),1,3,false,false,true))
				
			} 
			
			
			// get some color schemes, we'll cycle from one to other
			colorPalettes = new Array()
			
			for each (var scheme in ["fireHL","purpleHL","oceanHL","limeHL"]) {
				//colorPalettes.push(Colors.buildColorMap(scheme,0xFF,true))
				colorPalettes.push(Colors.buildColorMap(scheme))
			}
			/*
			for each (var scheme in ["fireHL","fireHL"]) {
				colorPalettes.push(Colors.buildColorMap(scheme))
			}
			*/
			colorMap = new Array(256)
			colorMapTo = colorMapFrom = colorPalettes[0]
			
			// create color transform and drop shadow filter 
			cF = new ColorTransform(1,1,1,0.95,0,0,0,0)

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
			var power:Number = 0.3*beats[256]
			
			// USE THIS FOR FADE OUT
			//this.alpha =  Beat.detect().power/0xFF
			
			if (power > 0) {
				// if no sound, start the countdown to deactivate
				countDown = 50;
				if (!visible) visible = true
			} else {
				if (countDown == 0) {
					visible = false
					return
				}
				countDown--
			}
			
			var i:uint
			
			// scale previously drawed frame
			power += 0.01*countDown
			
			var subbands:uint = 256
			var count:Number = beats[256]
			offset += 3*power
			
			//if (count > 0) trace(1-count/0xFF)
			
			var m:Number = Math.max(0.9,Math.min(0.99,1-((count+countDown/10)/0xFF)))
			
			if (countDown < 5) m=0.7
			cF.alphaMultiplier = m
			bBuffer.colorTransform(box,cF)
			
			//bBuffer.colorTransform(bData.rect,new ColorTransform(1,1,1,0.9,0,0,0,0))
			
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
				
				
				var sh:Shape = new Shape()
				sh.graphics.clear()
				//sh.graphics.lineStyle(uint(Math.random()*30+2),0,.05);
				
				for (i=1;i<255;i++) {
					if (beats[i] > 0) {
						sh.graphics.lineStyle(uint(Math.random()*30+2),0,.05);
						//sh.graphics.lineStyle(uint(Math.min(32,beats[i]/4)),0,0.2*(1-beats[i]/0xFF));
						
						var ff:uint = Math.random()*64
						
						sh.graphics.moveTo(-32,h*((i+offset) % subbands)/subbands)
						sh.graphics.curveTo(w/2+Math.sin(offset/64)*(i)/subbands*w, h/2+Math.cos(offset/57)*i/subbands*h, w+32,h*(subbands-((i + count) % subbands))/subbands);
	
						count++
					}
					
					
				}
				
				bBuffer.draw(sh)
			
			
			}
			
			
			
			bData.lock()
			
			if (bMask) {
				bData.paletteMap(bBuffer,box,Geom.origin,null,null,null,colorMap)
				bData.copyPixels(bData,box,Geom.origin,bMask,Geom.origin)
			} else {
				bData.paletteMap(bBuffer,box,Geom.origin,null,null,null,colorMap)
			}
			
			bData.unlock()
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(computeLoop)
			super.destroy()
		}
				
	}
}
/* commentsOK */