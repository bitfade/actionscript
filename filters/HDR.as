/*

	High Dynamic Range bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class HDR extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
		
			var bx:uint = 0
			var by:uint = 0
			
		
			var bColor:BitmapData = Bdata.create(w+bx,h+by)
			var box:Rectangle = bColor.rect
			
			var bBuffer:BitmapData //= bColor.clone()
			
			
			var r:Number = 0.212671;
			var g:Number = 0.715160;
			var b:Number = 0.072169;
			
			var CMF:ColorMatrixFilter = new ColorMatrixFilter(
				[r, g, b, 0, 0,
				 r, g, b, 0, 0,
				 r, g, b, 0, 0,
				 0, 0, 0, 1, 0]
			)
			

			var mat:Matrix = Geom.getScaleMatrix(Geom.getScaler("fill","center","center",snap.width/4,snap.height/4,snap.width,snap.height))

			bBuffer = Snapshot.take(new Bitmap(snap),null,0,0,mat)
			
			var bGray:BitmapData = bBuffer.clone()
			
			
			bGray.applyFilter(bBuffer,box,Geom.origin,CMF)
			
			bBuffer.threshold(bGray,bBuffer.rect,Geom.origin, "<",100, 0, 0xFF);
			
			bBuffer.applyFilter(bBuffer,bBuffer.rect,Geom.origin,new BlurFilter(8,8,2))
			
			//bColor.copyPixels(snap,box,new Point(bx >> 1,by >> 1))
			mat = Geom.getScaleMatrix(Geom.getScaler("fillmax","center","center",snap.width,snap.height,snap.width/4,snap.height/4))
			mat.tx = bx >> 1
			mat.ty = by >> 1
			
			
			
			
			bColor.draw(bBuffer,mat,new ColorTransform(1,1,1,1,0,0,0,0),"add",null,true)
			
			bBuffer = Gc.destroy(bBuffer)
			bGray = Gc.destroy(bGray)
			
			
			return bColor
			//return bBuffer
			
		}			
	}
}
/* commentsOK */