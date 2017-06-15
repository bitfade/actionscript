/*

	This class is used to build a light glow

*/
package bitfade.objects.light { 

	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	public class Glow {
		
		public static function build(size:uint):BitmapData {
		
			// the glow
			var bGlow:BitmapData = new BitmapData(size,size,true,0)
			
			// temp buffers
			var bBuffer:BitmapData = bGlow.clone()
			
			// some geom stuff
			var origin:Point = new Point()
			var box:Rectangle = bGlow.rect
			
			// shape used to draw
			var sh:Shape = new Shape()
			
			// matrix for gradients
			var mat = new Matrix()
			
			size = size >> 1
			
			// radious
			var rad:Number = size/1.2
			
			mat.createGradientBox(2*rad, 2*rad, 0, -rad,-rad);  
            
            // draw outer gradient
            with (sh.graphics) {
				beginGradientFill(GradientType.RADIAL, [0,0,0], [.05,0.05,0], [0,200,255], mat,"pad","linear");
				drawCircle(0,0,rad)
				endFill()

			}
			
			mat.createBox(1,1,0,size,size)
			bGlow.draw(sh,mat)
			
			// draw circle
			with (sh.graphics) {
				clear()
				beginFill(0,.1);	
				drawCircle(0,0,size/2.2)
				drawCircle(0,0,size/2.2-4)

			}
			
			bBuffer.draw(sh,mat)
			bBuffer.applyFilter(bBuffer,box,origin,new BlurFilter(4,4,2))
			bGlow.copyPixels(bBuffer,box,origin,null,null,true)
			
			rad = size/2.3
			
			mat.createGradientBox(2*rad, 2*rad, 0, -rad,-rad);  
			
			// draw inner gradient
			with (sh.graphics) {
				clear()			
				beginGradientFill(GradientType.RADIAL, [0,0,0,0,0], [1,0.5,0.4,.2,0], [0,32,64,128,255], mat,"pad","linear");
				drawCircle(0,0,rad)
				endFill()
			}
			
			mat.createBox(1,1,0,size,size)
			bGlow.draw(sh,mat)
			
			return bGlow
		
		}
 
	}
}
