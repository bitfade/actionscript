/*

	Glow bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Autocrop extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
				
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
		
			bitfade.utils.Crop.auto(snap)
			
			trace(snap.height)
			
			return snap
			
		}			
	}
}
/* commentsOK */