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
	
	public class OutlineHit extends bitfade.effects.cinematics.Cinematic  {
	
		// other bitmapDatas
		protected var bOutline:BitmapData;
		
		// for fadeIn/fadeOut
		protected var fadeInFactor:Number = 0
		protected var fadeOutFactor:Number = 0
		protected var translateFractor:Number = 0
		
		protected var savedX:int
		protected var savedY:int
		
		protected var bMapGlow:Bitmap;
		
		
		// constructor
		public function OutlineHit(t:DisplayObject = null) {
			super(t)
		}
		
		// crteate the effect
		public static function create(...args):Effect {
			return Effect.factory(bitfade.effects.cinematics.OutlineHit,args)
		}
						
		override protected function build():void {
			//defaults.blendMode = "add"
			//defaults.blendMode = "normal"
			
			defaults.style = "dark"
			defaults.flyBy = "left"
			defaults.offset = 30
			
			super.build()
		}
						
		// create bitmapDatas
		override protected function buildBitmaps():void {
		
			conf.areaX = 1
			conf.areaY = 1
			
			
			super.buildBitmaps()
			
			//ease = Expo.Out
			ease = Cubic.Out
			
		}
		
		override protected function fixBmapsPosition():void {
			super.fixBmapsPosition()
			
			if (bMapGlow) {
				bMapGlow.x = bMap.x - 8
				bMapGlow.y = bMap.y - 8
			}
			
		}
						
		// set effects preferences
		public function oulineFadeIn(...args):Effect {
			
			var totalTime:Number = args[0]
			
			
			target.alpha = 0
			bMap.alpha = 0
			
			bMap.blendMode = conf.style == "light" ? "normal" : "add"
			
			var color:uint = conf.style == "light" ? 0 : 0xFFFFFF
			
			bData.applyFilter(rasterizedTarget,bData.rect,Geom.origin,new DropShadowFilter(0,0,color,1,2,2,1,3,true,true,false))
				
			var bHDR:BitmapData = bitfade.filters.Glow.apply(new Bitmap(rasterizedTarget))
			
			bMapGlow = new Bitmap(bHDR)			
			
			bMapGlow.blendMode = conf.style == "light" ? "overlay" : "add"
			bMapGlow.alpha = 0
			
			
			addChild(bMapGlow)
			fixBmapsPosition()
			
			worker = worker_outlineHit
			
			return this
		}
		
		// do the magic!
		protected function worker_outlineHit(time:Number):void {
			
			//target.alpha = time
			bMap.alpha = 1
			
			if (time == 0) {
				savedX = x
				savedY = y
			
			}
			
			switch (conf.flyBy) {
				default:
					x = savedX
					y = savedY
				break; 
				case "left": 
					x = int(savedX - (1-time)*conf.offset)
				break;
				case "right": 
					x = int(savedX + (1-time)*conf.offset)
				break;
				case "top": 
					y = int(savedY - (1-time)*conf.offset)
				break;
				case "bottom": 
					y = int(savedY + (1-time)*conf.offset)
				break;
					
			}
			
			var part1:Number = 1
			var part2:Number = 1
			var part3:Number = 1
			
			time = 3*time
			
			part1 = Math.min(1,time)
			part2 = part1 < 1 ? 0 : Math.min(1,time-1)
			part3 = part2 < 1 ? 0 : Math.min(1,time-2)
			
			bData.lock()
			
			bMap.scrollRect = Geom.rectangle(0,0,w,h*part1)
			bMap.alpha = part1
			
			if (part2 > 0) {
				bMapGlow.alpha = part2
			}
			
			if (part3 > 0) {
				bMap.alpha = 1-part3
				bMapGlow.alpha = 1-part3
				target.alpha = part3
				
			}
			
			
			bData.unlock()
			
				
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