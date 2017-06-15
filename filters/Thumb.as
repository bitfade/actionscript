/*

	Thumb bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.utils.*
	import bitfade.ui.frames.*
	
	public class Thumb extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject,style:String = "default.light"):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
			
			var bColor:BitmapData = Snapshot.take(bitfade.ui.frames.Shape.create(style,w+32,h+32,0,0))
			
			bColor.copyPixels(snap,snap.rect,Geom.point(16,16),null,null,true)
			
			return bColor
			
		}			
	}
}
/* commentsOK */