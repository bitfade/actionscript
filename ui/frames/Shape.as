/*

	This class is used draw background frames

*/
package bitfade.ui.frames { 
	
	import flash.display.*
	import flash.geom.*
	
	public class Shape  {
	
		// colors
		// 0xFF0000
		public static var conf:Object = {
			"default.dark": 	[0x404040,0,0x181818,0x404040,0xA0A0A0,0x303030,0x101010,0x202020],
			"default.light": 	[0xD0D0D0,0xFFFFFF,0xD0D0D0,0xA0A0A0,0xE0E0E0,0xA0A0A0,0x404040,0xFFFFFF],
			"default.ocean": 	[0xA028ABEB,0xFFA2DEFF,0xFFFFFFFF,0xFFFFFF,0xFFFFFF,0xFFFFFF,0xFFFFFF,0xFFFFFF]
		}
		
		// static method used to create the frame
  		public static function create(type:String,w:uint,h:uint,mw:uint,mh:uint,colors:Array = null,dg:Graphics = null,rs:Number = -1):flash.display.Shape {
  			
  			w--
  			h--
  			
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
			var roundSize = rs >= 0 ? rs : uint((w/2+h/2)/9)
			
			mat.createGradientBox(w*2.5,h*2.5,0,-w*2.5/2,-h*2.5/2);
			dg.beginGradientFill(GradientType.RADIAL, 
				[colors[0],colors[1],colors[2]],
				[1,1,1],
				[0,180,255],
				mat,"pad","linear");
				
			dg.lineStyle(1,0,1,true)
			
			
			mat.createGradientBox(w*2,h*2,0,-w*2/2,-h*2/2);
			
			dg.lineGradientStyle(GradientType.RADIAL, 
				[colors[3],colors[4],colors[5]],
				[1,1,1],
				[0,128,255],
				mat,"pad","linear");
			dg.drawRoundRect(0,0,w,h,roundSize,roundSize)
			dg.endFill();
			  			
			  			
			if (mh>0 && mw>0) {
				var x:uint = mw-1
				var y:uint = mh-1
				
				dg.lineStyle(1,colors[6],1,true)			
				dg.moveTo(x,h-y)
				dg.lineTo(x,y)
				dg.lineTo(w-x,y)
				dg.lineStyle(1,colors[7],1,true)
				dg.lineTo(w-x,h-y)
				dg.lineTo(x,h-y)
			}
						
 			// return shape
			return sh
  		
  		}
  		
	}
}
/* commentsOK */