/*

	This class is used draw background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Reflection extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 	[0x505050,0,0xFFFFFF,0,0x202020,0x202020],
			"light": 	[0xB0B0B0,0xFFFFFF,0xA0A0A0,0xFFFFFF,0xCCCCCC,0xFFFFFF]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Reflection()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  			var gw:uint = w
  		
  			mat.createGradientBox(gw,h, Math.PI/2,(w-gw)/2,h/2);
			dg.lineStyle(0,0,0)
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[0],colors[1]],
				[1,1],
				[0,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			gw = w*2
			
			mat.createGradientBox(gw,h*2, Math.PI/2,(w-gw)/2,(h-h*2));
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[2],colors[3]],
				[.3,0],
				[0,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			dg.lineStyle(1);
			dg.lineGradientStyle(GradientType.RADIAL, 
				[colors[4],colors[5]],
				[0,.5],
				[0,255],
				mat,"pad","linear")
			
			for (var i:uint = 0;i<h; i+=2) {
				dg.moveTo(0,i)
				dg.lineTo(w,i)
			}
  		}
  		
	}
}
/* commentsOK */