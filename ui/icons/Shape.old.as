/*

	This class draws various icon shapes

*/
package bitfade.ui.icons { 
	
	import flash.display.*
	import flash.geom.*
	
	public class shape  {
	
		// color and alpha
		public static var conf:Object = {	
			color: 0xC0C0C0
		}
		
		// create the shaper
  		public static function create(type:String,size:uint=16,w:uint=16,color:int = -1):Shape {
  			
  			var bsize:Number = size*0.7
			var boff:Number = (size-bsize)/2
			
					
			var sh = new Shape()
					
			/*
				rant: this is when it get's hard to be a coder...
				
				however, all this shapes are drawed using graphics AS3 methods
				
			*/
			
			if (color < 0) color = conf.color
			
			with (sh.graphics) {
				beginFill(0,0)
				drawRoundRect(0,0,Math.max(size,w),size,8,8)
				endFill()
			
				beginFill(color,1)
				
				switch (type) {
					case "prev":
						moveTo(boff+bsize,boff+bsize)
						lineTo(boff+bsize,boff)
						lineTo(boff,boff+bsize/2)
						lineTo(boff+bsize,boff+bsize)
					break;
					case "play":
					case "next":
						moveTo(boff,boff)
						lineTo(boff,boff+bsize)
						lineTo(boff+bsize,boff+bsize/2)
						lineTo(boff,boff)
					break
					case "pause":
						drawRect(boff+bsize/8,boff,bsize*2/8,bsize)
						drawRect(boff+bsize*5/8,boff,bsize*2/8,bsize)
					break;
					
					case "volume":
						moveTo(boff,boff+bsize/3)
						lineTo(boff,boff+bsize*2/3)
						lineTo(boff+bsize/3,boff+bsize*2/3)
						lineTo(boff+bsize*3/4,boff+bsize)
						lineTo(boff+bsize*3/4,boff)
						lineTo(boff+bsize/3,boff+bsize/3)
						lineTo(boff,boff+bsize/3)
						endFill()
						
						lineStyle(1,color,0.5)
						
						moveTo(boff+bsize*3/4+2,boff+2)
						curveTo(boff+bsize*1.2,boff+bsize/2,boff+bsize*3/4+2,boff+bsize-2)
						
						lineStyle(1,color,0.6)
						
						moveTo(boff+bsize,boff)
						curveTo(boff+bsize*1.6,boff+bsize/2,boff+bsize,boff+bsize)
					break;
					
					case "fullscreen":
					
						lineStyle(2,color,1)
						beginFill(color,1)
						drawRect(boff+4,boff+4,bsize-8,bsize-8)
						endFill()
						
					
						endFill()
						lineStyle(2,color,1)
						moveTo(boff,boff+7)
						lineTo(boff,boff)
						lineTo(boff+7,boff)
						
						moveTo(boff+bsize-1,boff+bsize-7)
						lineTo(boff+bsize-1,boff+bsize-1)
						lineTo(boff+bsize-7,boff+bsize-1)
						
						
					
					break
					case "zoom":
						endFill()
						lineStyle(2,color,1,true)
						
						var lo:Number = uint(w-2-bsize)
						var lw:Number = w-5
						
						drawCircle(boff+bsize/3,boff+bsize/3,bsize/3)
						
						lineStyle(3,color,1,true)
						
						moveTo(boff+bsize/3,boff+bsize*2/3+2)
						lineTo(boff+bsize/3,boff+bsize)
						
						lineStyle(1,color,1,true)
						
						moveTo(boff+bsize/3,boff+3)
						lineTo(boff+bsize/3,boff+bsize/3+1)
						
						moveTo(boff+3,boff+bsize/3)
						lineTo(boff+bsize/3+1,boff+bsize/3)
						
						lineStyle(1,color,1,true)
						
						moveTo(boff+bsize,boff+1)
						lineTo(boff+lw,boff+1)
						
						moveTo(boff+bsize,boff+bsize)
						lineTo(boff+lw,boff+bsize)
						
					break
					
				}
			}
			
			return sh
  		
  		}
  		
	}
}