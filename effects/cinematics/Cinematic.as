/*

	Base class for cinematics effects

*/
package bitfade.effects.cinematics {
	
	import flash.display.*
	import flash.geom.*
	
	import bitfade.core.*
	import bitfade.effects.*
	import bitfade.utils.*
	
	public class Cinematic extends bitfade.effects.Tween  {
	
		protected var conf:Object
	
		// default values
		protected var defaults:Object = {
			areaX:2,
			areaY:2,
			blendMode: "add",
			fadeIn: -1,
			fadeOut: -1
		}
	
		// bitmaps
		protected var bMap:Bitmap
		protected var bData:BitmapData
		protected var rasterizedTarget:BitmapData
		protected var area:Rectangle
		
		// size
		protected var w:uint
		protected var h:uint
		
		// position
		public var offset:Point = new Point()
		
		protected var box:Rectangle
		
		// constructor
		public function Cinematic(t:DisplayObject = null) {
			super(t)
		}
		
		override public function start(...args):Effect {
			// set size and default values
			w = args[0]
			h = args[1]
			
			conf = Misc.setDefaults(args[2],defaults,true)
			
			buildBitmaps()
			
			return super.start()
		}
		
		// build the effect
		override protected function build():void {
			super.build()
			bMap = new Bitmap()
			addChild(bMap)
		}
		
		// create needed bitmapDatas
		protected function buildBitmaps():void {
			
			rasterizedTarget = Crop.auto(Snapshot.take(target,rasterizedTarget),offset)
			
			// compute effect size
			// CHECK THIS 
			w = Math.max(w,rasterizedTarget.width)
			h = Math.max(h,rasterizedTarget.height)
			// CHECK END
			w = Math.min(w,int(rasterizedTarget.width*conf.areaX))
			h = Math.min(h,int(rasterizedTarget.height*conf.areaY))
			
			
			bData = new BitmapData(w,h,true,0)
			box = bData.rect
			bMap.bitmapData = bData
			
			fixBmapsPosition()
			
		}
		
		// fix bitmaps position
		protected function fixBmapsPosition():void {
			bMap.x = int((rasterizedTarget.width-w)/2+offset.x)
			bMap.y = int((rasterizedTarget.height-h)/2+offset.y)						
		}
		
		override public function get realWidth():uint {
			return rasterizedTarget ? rasterizedTarget.width : target.width
		} 
		
		override public function get realHeight():uint {
			return rasterizedTarget ? rasterizedTarget.height : target.height
		}
		
		public static function create(...args):Effect {
			return Effect.factory(Cinematic,args)
		}
		
		// destruct effect
		override public function destroy():void {
			bData = undefined
			super.destroy()
		}
		
		
	}
}
/* commentsOK */