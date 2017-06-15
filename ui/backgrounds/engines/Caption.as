/*

	This class is used draw background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Caption extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 		[0xE0E0E0,0x404040,0,-1],
			"dark.matte": 	[0xE0E0E0,0x404040,0,0x101010],
			"light": 		[0,0xCCCCCC,0xEEEEEE,0xFEFEFE],
			"light.matte": 	[0,0xCCCCCC,0xEEEEEE,0xFEFEFE]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Caption()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  		
  			// not trasparent
  			if (colors[2] >= 0) {
  				dg.beginFill(colors[3],type == "light" ? 0.9 : 1)
  				dg.drawRect(0,0,w,h)
  			}
  			
  			mat.createGradientBox(w*2,h*8, Math.PI/2,-w/2,-4*h);
			dg.lineStyle(0,0,0)
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[1],colors[2]],
				[.8,0],
				[0,100],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			dg.lineStyle(1);
			dg.lineGradientStyle(GradientType.RADIAL, 
				[colors[0],colors[2]],
				[1,0],
				[0,100],
				mat,"pad","linear")
			dg.moveTo(0,0)
			dg.lineTo(w,0)
			
			dg.lineGradientStyle(GradientType.RADIAL, 
				[colors[1],colors[2]],
				[.8,0],
				[0,100],
				mat,"pad","linear")
			
			for (var i:uint = 2;i<h; i+=2) {
				dg.moveTo(0,i)
				dg.lineTo(w,i)
			}
			
  		}
  		
	}
}
/* commentsOK */