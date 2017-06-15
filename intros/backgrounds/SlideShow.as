/*

	Slideshow background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.utils.*
	
	import bitfade.utils.*
	import bitfade.effects.*
	import bitfade.transitions.*
	import bitfade.easing.*
	
	public class SlideShow extends Background {
	
		// needed bitmaps
		protected var bMap:Bitmap
		protected var bData:BitmapData
		protected var bBuffer:BitmapData
		
		// call when ready
		protected var onReadyCallBack:Function
		
		// transition manager
		protected var tManager:bitfade.transitions.Advanced
		
		// source, destination bitmaps
		protected var from:BitmapData
		protected var to:BitmapData
		
		// transition manager
		protected var transitionLoop:RunNode
		protected var started:uint;
		
		protected var duration:Number = 1000
		protected var delay:Number = 1000
		
		// transition types 
		protected var transitionType:String = "hilight"
		protected static var tRandom:Array = ["slideLeft","slideRight","slideTop","slideBottom","expandWidth","expandHeight","white","hilight"]
		
		public function SlideShow(...args) {
			configure.apply(null,args)
		}
		
		override protected function init():void {
			super.init()
			
			if (onReadyCallBack != null) onReadyCallBack()
		}
		
		override public function onReady(cb:Function) {
			onReadyCallBack = cb
		}
		
		override public function start():void {
			// create the bitmaps
			bData = Bdata.create(w,h)
			bBuffer = bData.clone();
			bMap = new Bitmap(bData)
			
			addChild(bMap)
			
			// create the transition manager
			tManager = new bitfade.transitions.Advanced(bData,bBuffer)
			tManager.crossFade = true
			
			// add the event listener
			transitionLoop = Run.every(Run.FRAME,computeTransition)
		}
		
		// add a new destination image
		override public function show(content:*,opts:Object = null):void {
			
			// handle blank source
			if (!from) {
				from = bData.clone()
			} else {
				from.copyPixels(bData,bData.rect,Geom.origin) 
			}
			
			// handle blank destination
			if (content) {
				to = Bitmap(content).bitmapData
			} else {
				to = null
			}
			
			
			// set transition type
			opts = Misc.setDefaults(opts,conf)
			transitionType = opts.transition
			
			if (transitionType == "random") {
				transitionType = tRandom[uint(Math.random()*(tRandom.length-1)+0.5)]
			}
			
			try {
				tManager[transitionType]
			} catch (e:*) {
				transitionType = "fade"
			}
			
			// set duration/delay
			duration = opts.duration*1000
			delay = opts.delay*1000
			
			duration += delay
			
			started = getTimer();
			paused = false;
			
		}
		
		// display transition steps
		protected function computeTransition() {
			if (paused || !transitionType) return
			
			var elapsed:Number = Math.min(duration,getTimer()-started)
			
			if (elapsed<delay) return
			// update transition manager
			tManager[transitionType](from,to,elapsed-delay,duration-delay)
			if (elapsed == duration) {
				paused = true;
			}
			
		}
		
		public static function get resourceType():String {
			return "display"
		}
		
		
		
		// clean up
		override public function destroy():void {
			bBuffer.dispose()
			bBuffer = undefined
			if (from) from.dispose()
			from = undefined
			Run.reset(transitionLoop)
			super.destroy()
		}
		
	}

}
/* commentsOK */