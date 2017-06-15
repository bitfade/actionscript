/*

	Clean bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Clean extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var bColor:BitmapData = snap.clone()
			
			bColor.applyFilter(snap,bColor.rect,Geom.origin,new BevelFilter(1,225,0xFFFFFF,1.0,0x000000,.5,0,0,.5,2,"inner",false))
			
			return bColor
			
		}			
	}
}
/* commentsOK */