/*

	Outline Hit cinematic effect

*/
package bitfade.effects.cinematics {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.core.*
	import bitfade.effects.*
	import bitfade.utils.*
	
	import bitfade.data.*
	import bitfade.easing.*
	import bitfade.filters.*
	
	import bitfade.transitions.*
	
	public class Transition extends bitfade.effects.cinematics.Cinematic  {
	
		// other bitmapDatas
		protected var bOutline:BitmapData;
		
		// for fadeIn/fadeOut
		protected var fadeInFactor:Number = 0
		protected var fadeOutFactor:Number = 0
		protected var translateFractor:Number = 0
		protected var tManager:bitfade.transitions.Advanced;
		
		protected var savedX:int
		protected var savedY:int
		
		protected var bBuffer:BitmapData;
		
		
		// constructor
		public function Transition(t:DisplayObject = null) {
			super(t)
		}
		
		// crteate the effect
		public static function create(...args):Effect {
			return Effect.factory(bitfade.effects.cinematics.Transition,args)
		}
						
		override protected function build():void {
			defaults.blendMode = "add"
			
			defaults.flyBy = "left"
			defaults.offset = 30
			
			super.build()
		}
						
		// create bitmapDatas
		override protected function buildBitmaps():void {
		
			conf.areaX = 1
			conf.areaY = 1
			
			
			super.buildBitmaps()
			
			bMap.blendMode = conf.blendMode
			
			//ease = Expo.Out
			//ease = Cubic.Out
			ease = Linear.In
			
		}
		
		override protected function fixBmapsPosition():void {
			super.fixBmapsPosition()
		}
						
		// set effects preferences
		public function transition(...args):Effect {
			
			var totalTime:Number = args[0]
			
			
			target.alpha = 0
			bMap.alpha = 1
			
			bBuffer = Bdata.create(w,h)
			
			fixBmapsPosition()
			
			// advanced transition manager
			tManager = new bitfade.transitions.Advanced(bData,bBuffer)
			tManager.crossFade = true
			
			worker = worker_transition
			
			return this
		}
		
		// do the magic!
		protected function worker_transition(time:Number):void {
			
			tManager.slideTop(rasterizedTarget,null,time,1)
			
			/*
			bData.lock()
			bData.unlock()
			*/
				
		}
		
		// destroy effect
		override public function destroy():void {
			// add child
			
			var idx:uint = parent.getChildIndex(this)
			
			parent.addChildAt(target,idx)
			
			target.x = x
			target.y = y 
			
			super.destroy()
		}
		
		
	}
}
/* commentsOK */