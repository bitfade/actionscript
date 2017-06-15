/*

	This class is used draw background bars

*/
package bitfade.ui.bars { 
	
	import flash.display.*
	import flash.geom.*
	
	public class shape  {
	
		// colors
		public static var conf:Object = {
			"default.dark": 	[0x282828,0x191919,0x484848,0x202020],
			"default.light":	[0xF0F0F0,0xA0A0A0,0xFFFFFF,0x808080],
			"alternate.dark": 	[0x2F2F2F,0x494949,0x404040,0x343434],
			"alternate.light": 	[0x808080,0xF0F0F0,0xB0B0B0,0xC0C0C0],
			"vlike.dark": 		[0x7A7A7A,0x5B5B5B,0x3B3B3B,0x313131],
			"vlike.light": 		[0xFAFAFA,0xDBDBDB,0xBBBBBB,0xB1B1B1]
		}
		
		// static method used to create the bar
  		public static function create(type:String,w:uint,h:uint,colors:Array = null):Shape {
  			
  			// create a shape
  			var sh:Shape = new Shape()
					
			// set up matrix for gradient
			var mat:Matrix = new Matrix()
			mat.createGradientBox(w,h, Math.PI/2,0,0);  
			
			if (!conf[type]) type = "default.dark"
			
			if (!colors) {
				colors = conf[type]
			} else {
				for (var i:uint=0;i<colors.length;i++) {
					if (colors[i] < 0) colors[i] = conf[type][i]
				}
			}
			
			with (sh.graphics) {
				switch (type) {
					case "vlike.light":
					case "vlike.dark":
						// alternative gradient type
						lineStyle(1,Math.max(colors[0]-0x202020,0),1,true)
						beginGradientFill(GradientType.LINEAR, 
							[colors[0],colors[1],colors[2],colors[3]],
							[1,1,1,1],
							[0,127,128,255],
							mat,"pad","linear");
						drawRect(0,0,w,h)
						endFill()
						sh.scale9Grid = new Rectangle(1,1,w-2,h-2)
					break;
					
					case "alternate.light":
					case "alternate.dark":
						// alternative gradient type
						beginGradientFill(GradientType.LINEAR, 
							[colors[0],colors[1],colors[1],colors[2],colors[2],colors[1],colors[3]], 
							[1,1,1,1,1,1,1], 
							[0,32,64,96,128,255-16,255], 
							mat,"pad","linear");
						drawRect(0,0,w,h)
						endFill()
					break;
					
					default:
					
						// default gradient type
						lineStyle(1,colors[2],1,true)
						beginGradientFill(GradientType.LINEAR, 
							[colors[0],colors[1]],
							[1,1],
							[0,255],
							mat,"pad","linear");
						drawRect(0,0,w,h)
						endFill()
						
						
						lineStyle(0,0,0,true)
						beginFill(0xFFFFFF,type == "default.dark" ? .1 : .5)
						moveTo(1,h/8)	
						curveTo(w/2, h, w-1,h/8)
						lineTo(w-1,1)
						lineTo(1,1)
						endFill()
						
						lineStyle(1,colors[3],1,true)
						moveTo(0,h)
						lineTo(w,h)
						lineTo(w,0)
						
						sh.scale9Grid = new Rectangle(1,1,w-2,h-2)			
				}
			}
			
			// return shape
			return sh
  		
  		}
  		
	}
}
/* commentsOK */