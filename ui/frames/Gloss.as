/*

	This class is used draw frame gloss

*/
package bitfade.ui.frames { 
	
	import flash.display.*
	import flash.geom.*
	
	public class Gloss  {
	
		
		// static method used to create the frame
  		public static function create(w:uint,h:uint,colors:Array = null):flash.display.Shape {
  			
  			var sh:flash.display.Shape = new flash.display.Shape();
			var dg:Graphics = sh.graphics
			var mat = new Matrix()
			
			mat.createGradientBox(w,h/3,Math.atan(w/h),0,0);
			dg.beginGradientFill(GradientType.LINEAR, 
				[0xFFFFFF,0xFFFFFF],
				[.2,.04],
				[0,255],
				mat,"pad","linear");
			
			dg.moveTo(0,0)
			dg.lineTo(0,h*2/3)
			dg.curveTo(w/4,h/8,w*1.5,0)
			dg.lineTo(w,0)	
			dg.endFill();
			  			
			/*
			mat.createGradientBox(w*2.5,h*2.5,0,-w*2.5/2,-h*2.5/2);
			dg.lineStyle(0,null,null,true)
			dg.beginGradientFill(GradientType.RADIAL, 
				[0xFFFFFF,0xFFFFFF,0xFFFFFF],
				[.4,.0,.15],
				[0,170,255],
				mat,"pad","linear");
			dg.drawRect(9,11,w-17,h-21)
			dg.endFill()
			*/
			  			
			// return shape
			return sh
  		
  		}
  		
	}
}
/* commentsOK */