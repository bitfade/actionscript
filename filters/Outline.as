/*

	Outline bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Outline extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var bColor:BitmapData = snap.clone()
			
			bColor.applyFilter(snap,bColor.rect,Geom.origin,new GlowFilter(0, 1, 2,2,1, 2,false))
			
			return bColor
			
		}			
	}
}
/* commentsOK */