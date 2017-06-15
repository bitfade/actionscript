/*

	This class is used draw background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Line extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 		[0xFFFFFF],
			"light": 		[0]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Line()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  			
  			var gw:uint = w*2
			
			mat.createGradientBox(gw,h*2, Math.PI/2,(w-gw)/2,(h-h*2));
			
			dg.lineStyle(h);
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[0],colors[0]],
				[1,0],
				[0,255],
				mat,"pad","linear")
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			
			
  		}
  		
	}
}
/* commentsOK */