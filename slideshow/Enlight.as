/*

	Pure actionscript 3.0 slideshow with enlight effect 
	this extends bitfade.slideshow.effect which has common functions

*/
package bitfade.slideshow {

	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.geom.*
	
	import bitfade.utils.*
	import bitfade.slideshow.slideshow
	
	public class enlight extends bitfade.slideshow.slideshow {
	
		// some defaults, ** SEE HELP FILE ** all covered there
		// these are overwrited by xml settings, so no need to change here
		
		protected var effectsDefaults:Object = {
			enlight : {
				enabled: true,
				bars: 3,
				size: 20,
				speedMin:1,
				speedMax:3,
				intensity: 50,
				persistence: 95,
				blur: 64,
				mode: "add",
				xRange:0,
				xMin:0,
				vRange:0,
				vMin:0
			},
			color: {
				enabled:true,
				color: 0,
				brightness: -0.2
			},
			original: {
				enabled: true
			}
		}
		
		// color filter
		protected var cM:ColorMatrixFilter;
		
		// some bitmapDatas
		protected var bMask:BitmapData
		protected var bBar:BitmapData
		protected var bBuffer2:BitmapData
		
		// color transform to fade out
		protected var fadeCT:ColorTransform
		
		// point
		protected var bP:Point
		
		// constructor
		public function enlight(conf) {
			// call parent constructor
			super(conf)
		}
		
		// custom init
		override protected function customInit() {
		
			// override defaults with xml settings
			if (!conf.effects) {
				conf.effects = effectsDefaults
			} else {
				conf.effects = misc.setDefaults(conf.effects[0],effectsDefaults)
			}
			
			// set the color filter
			with (conf.effects.color) {
				if (enabled) {
					cM = new ColorMatrixFilter([
						.34,.33,.33,brightness,color >>> 16 & 0xFF,
						.33,.34,.33,brightness,color >>> 8 & 0xFF,
						.33,.33,.34,brightness,color & 0xFF,
    	 				0,0,0,1,0 
					])
				}
			
			}
			
			// create some needed stuff
			bP = new Point();
			bMask = bData.clone()
			bBuffer2 = bData.clone()
			bBar = bData.clone();
			
			
			conf.effects.enlight.bar = new Array(conf.effects.enlight.bars)
			
			// create stuff for enlight effect
			with (conf.effects.enlight) {
				if (!enabled) return
		
				// create the bar (bitmap)
				bBar.fillRect(new Rectangle(size+blur,0,size,h),uint(intensity*0xFF/100) << 24)
				bBar.applyFilter(bBar,box,origin,new BlurFilter(blur,blur,2))
			
				xMin = -blur-size
				xRange = (w-blur+2*size)
				
				vRange = speedMax-speedMin
				vMin = speedMin
				
				// create defined number of random moving light bars
				for (var i:uint=0;i<bars;i++) {
					bar[i] = {
						s : Math.random()*xRange+xMin,
						e : Math.random()*xRange+xMin,
						v : Math.random()*vRange+vMin,
						t : 0
					}
				}
				
				// create the colorTransform
				fadeCT = new ColorTransform(1,1,1,persistence/100,0,0,0,0)
			}
		}
		
		// this will render the effect
		private function enlightEffect(bd:BitmapData) {
		
			// apply the color filter
			bData.applyFilter(bd,box,origin,cM)
			
			// if no enlight, bye
			if (!conf.effects.enlight.enabled) return
			
			bBuffer2.colorTransform(box,fadeCT)
			
			// for each bar
			for (var i:uint=0;i<conf.effects.enlight.bars;i++) {
				with (conf.effects.enlight.bar[i]) {
					
					// get the x position
					bP.x = int(ease.InOutCubic(t,s,(e-s),100))
					
					// draw the bar to buffer
					bBuffer2.copyPixels(bBar,box,bP,null,null,true)
					
					// update time
					t += v
					
					// if time reach max, set another random position
					if (t >= 100) {
						t = 0
						s = e
						e = Math.random()*conf.effects.enlight.xRange+conf.effects.enlight.xMin
						v = Math.random()*conf.effects.enlight.vRange+conf.effects.enlight.vMin
					}
					
				}
			}
			
			// draw the buffer to screen
			bBuffer.copyPixels(bd,box,origin,bBuffer2,origin)
			bData.draw(bBuffer,null,null,conf.effects.enlight.mode)
						
		}
		
		// render function, overrides parent one
		override protected function render(bd:BitmapData=null) {
			if (!bd) {
				if (!pz) return
				pz.update()
				bd = pz.bData
			} 
			
			
			var showOriginal:Boolean = conf.effects.original.enabled
			
			if (!(conf.effects.enlight.enabled || conf.effects.color.enabled)) {
				// if no effects, show original item
				bData.copyPixels(bd,box,origin)
			} else if (showOriginal && overCounter > 0 && overCounter < overCounterMax) {
				// enlight effect active
				enlightEffect(bd)
				
				// add (faded) original image
				bBuffer.fillRect(box,uint(overCounter/overCounterMax*0xFF) << 24)
				bData.copyPixels(bd,box,origin,bBuffer,origin,true)
			} else {
				if (!showOriginal || overCounter == 0) {
					// if no mouse over, enlight only
					enlightEffect(bd)
				} else {
					// no enlight, just the original
					bData.copyPixels(bd,box,origin)
				}
			}
			
			// render caption
			renderCaption();
			
			// render controls
			renderControls();
		}
	}

}
	