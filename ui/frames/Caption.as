/*

	This class is used draw background frames

*/
package bitfade.ui.frames { 
	
	import flash.display.*
	import flash.geom.*
	
	public class Caption  {
	
		// colors
		// 0xFF0000
		public static var conf:Object = {
			"default.dark": 	[0x181818,0x303030],
			"default.light": 	[0xD0D0D0,0xFFFFFF]
		}
		
		// static method used to create the frame
  		public static function create(type:String,w:uint,h:uint,roundSize:uint = 4,colors:Array = null,dg:Graphics = null,rs:Number = -1):flash.display.Shape {
  			
  			if (!conf[type]) type = "default.dark"
  			
  			if (!colors) {
				colors = conf[type]
			} else {
				for (var i:uint=0;i<colors.length;i++) {
					if (colors[i] < 0) colors[i] = conf[type][i]
				}
			}
  			
  			var sh:flash.display.Shape
  			
  			if (!dg) {
  				sh = new flash.display.Shape();
  				dg = sh.graphics
  			}
  			
  			var mat = new Matrix()
			
			mat.createGradientBox(w,h,Math.PI/2,0,0);
			dg.beginGradientFill(GradientType.LINEAR, 
				[colors[0],colors[1]],
				[1,1],
				[0,255],
				mat,"pad","linear");
			
			
			dg.drawRoundRect(0,0,w,h,roundSize,roundSize)
			dg.endFill();
			  			
			  			
			
						
 			// return shape
			return sh
  		
  		}
  		
	}
}
/* commentsOK */