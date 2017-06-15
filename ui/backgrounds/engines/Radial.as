/*

	This class is used draw background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Radial extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 		[0xE0E0E0,0x404040,0,-1],
			"dark.matte": 	[0xE0E0E0,0x404040,0,0x101010],
			"light": 		[0,0xCCCCCC,0xEEEEEE,0xFEFEFE],
			"light.matte": 	[0,0xCCCCCC,0xEEEEEE,0xFEFEFE]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Radial()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  		
  			mat.createGradientBox(w,h,0,0,0);
			dg.beginGradientFill(GradientType.RADIAL, 
				[0xFFFFFF,0xFFFFFF,0x32D6FF,0x000080,0x00000080],
				[1,1,1,1,1],
				[0,100,180,220,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			
  		}
  		
	}
}
/* commentsOK */