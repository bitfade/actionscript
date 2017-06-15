/*

	Glow bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Glow extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
			
			var blur:uint = 8
			var blur2:uint = blur << 1
			
			var scale:uint = 4
			
			var bColor:BitmapData = Bdata.create(w+blur2,h+blur2)
			var bBuffer:BitmapData = bColor.clone()
			
			var box:Rectangle = bColor.rect
			
			
			var mat:Matrix = Geom.getScaleMatrix(Geom.getScaler("fill","center","center",bColor.width/scale,bColor.height/scale,bColor.width,bColor.height))

			bColor.copyPixels(snap,box,new Point(blur,blur))

			bBuffer = Snapshot.take(new Bitmap(bColor),null,0,0,mat)
			bBuffer.applyFilter(bBuffer,box,Geom.origin,new BlurFilter(blur/scale,blur/scale,2))
			
			
			mat.invert()
			
			bColor.draw(bBuffer,mat,new ColorTransform(1,1,1,0.8,0,0,0,0),"overlay",null,true)
			
			bBuffer = Gc.destroy(bBuffer)
			
			return bColor
			
		}			
	}
}
/* commentsOK */