/*

	Over effect

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
	
	public class Over extends bitfade.effects.cinematics.Cinematic  {
	
		// other bitmapDatas
		protected var bOutline:BitmapData;
		
		
		// constructor
		public function Over(t:DisplayObject = null) {
			super(t)
		}
		
		// crteate the effect
		public static function create(...args):Effect {
			return Effect.factory(bitfade.effects.cinematics.Over,args)
		}
						
		override protected function build():void {
			defaults.blendMode = "add"
			
			mouseEnabled = false
			mouseChildren = false
							
			bMap = new Bitmap()
			addChild(bMap)
			
		}
						
		// create needed bitmapDatas
		override protected function buildBitmaps():void {
			
			rasterizedTarget = Crop.auto(Snapshot.take(target,rasterizedTarget),offset)
			
			// compute effect size
			w = rasterizedTarget.width+16
			h = rasterizedTarget.height+16
			
			bMap.bitmapData = bData
			
			x = target.x
			y = target.y
			
			ease = Linear.In
			
			bMap.blendMode = conf.blendMode
	
			
			fixBmapsPosition()
			
		}
		
				
		// set effects preferences
		public function over(...args):Effect {
			
			var totalTime:Number = args[0]
			
			
			bMap.alpha = 0
			
			bMap.bitmapData = bData = bitfade.filters.Glow.apply(new Bitmap(rasterizedTarget))
			
			
			fixBmapsPosition()
			
			worker = worker_over
			
			return this
		}
		
		// do the magic!
		protected function worker_over(time:Number):void {			
			bMap.alpha = ((time <= 0.5) ? Cubic.Out(time,0,1,0.5) : Linear.In(time-0.5,1,-1,0.5))*0.7
		}
		
		
		
	}
}
/* commentsOK */