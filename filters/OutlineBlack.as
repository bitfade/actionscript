/*

	Outline Black bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class OutlineBlack extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
		
			var bColor:BitmapData = Bdata.create(w,h)
			var box:Rectangle = bColor.rect
			
			var bBuffer:BitmapData = bColor.clone()
			
			// deal with forceBlack item setting
			if (false) {
				bBuffer.fillRect(box,0xFF303030)
				bColor.copyPixels(bBuffer,snap.rect,Geom.origin,snap,Geom.origin)				
			} else {
				bColor.copyPixels(snap,snap.rect,Geom.origin)
			}
			
			var dsF = bitfade.utils.Filter.DropShadowFilter(0,0,0,1,32,32,0.7,1,false,false,true)
			
			// if effect is enabled for current item, apply some filters	
			if (true) {
				bBuffer.applyFilter(bColor,box,Geom.origin,bitfade.utils.Filter.assign(dsF,4,45,0,1,8,8,2,2,true,false,false))
				bColor.applyFilter(bBuffer,box,Geom.origin,bitfade.utils.Filter.assign(dsF,2,225,0,1,16,16,1,2,true,false,false))
				bBuffer.applyFilter(bColor,box,Geom.origin,bitfade.utils.Filter.assign(dsF,1,45,0xFFFFFF,1,2,2,1,2,true,false,false))
				bColor.applyFilter(bBuffer,box,Geom.origin,bitfade.utils.Filter.GlowFilter(0,1,2,2,1,2,false,false))
			}
			
			bBuffer = Gc.destroy(bBuffer)
			
			return bColor
			
		}			
	}
}
/* commentsOK */