/*

	This class is used draw background gradient

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Linear extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 		[0x181818,0x303030,0xFFFFFF,0],
			"light": 		[0xFFFFFF,0xBBBBBB,0,0xFEFEFE]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Linear()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  			
  			mat.createGradientBox(w,h,Math.PI/2,0,0);
			dg.beginGradientFill(GradientType.LINEAR, 
				[colors[0],colors[1]],
				[1,1],
				[0,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			
			var gw:uint = w*2
			
			mat.createGradientBox(gw,h*2, Math.PI/2,(w-gw)/2,(h-h*2));
			
			dg.lineStyle(1);
			dg.lineGradientStyle(GradientType.RADIAL, 
				[colors[2],colors[3]],
				[.5,.1],
				[0,255],
				mat,"pad","linear")
			
			dg.moveTo(0,0)
			dg.lineTo(w,0)
			
			
			
  		}
  		
	}
}
/* commentsOK */