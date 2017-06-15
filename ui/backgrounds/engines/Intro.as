/*

	This class is used draw intro background

*/
package bitfade.ui.backgrounds.engines { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.ui.backgrounds.engines.Engine
	
	public class Intro extends bitfade.ui.backgrounds.engines.Engine  {
	
		// colors
		public static var conf:Object = {
			"dark": 	[0x707070,0x202020]
			//"dark": 	[0xBAE7FF,0x000020]
		}
		
		// static method used to create the frame
  		public static function create(...args):Shape {
  			return (new Intro()).build.apply(null,args)
  		}
  		
  		override public function draw():void {
  		
  			
  			var gw:uint = w*3
  			var gh:uint = h*2
	  		
	  		var alphas1:Array
	  		var alphas2:Array
	  		
	  		switch (type) {
	  			case "light":
	  				alphas1 = [1,.5]
	  				alphas2 = [1,.5]
	  			break;
	  			default:
	  				alphas1 = [1,0]
	  				alphas2 = [.5,0]
	  		}
	  		
	  		dg.beginFill(0,1)
	  		dg.drawRect(0,0,w,h)
	  		dg.endFill()
	  		
  			mat.createGradientBox(gw,gh, Math.PI/2,(0-gw)/2,(0-gh)/2);
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[0],colors[1]],
				alphas1,
				[0,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
			mat.createGradientBox(gw,gh, Math.PI/2,(2*w-gw)/2,(2*h-gh)/2);
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[0],colors[1]],
				alphas2,
				[0,255],
				mat,"pad","linear");
			dg.drawRect(0,0,w,h)
			dg.endFill()
			
  			
			
			
  		}
  		
	}
}
/* commentsOK */