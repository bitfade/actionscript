/*

	Thumb bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.utils.*
	import bitfade.ui.frames.*
	
	public class Box extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject,style:String = "dark",alpha:Number= 1,padding:uint = 16,rs:int = -1):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
			
			var bColor:BitmapData = Snapshot.take(bitfade.ui.frames.Shape.create("default."+style,w+padding*2,h+padding*2,0,0,null,null,rs))
			bColor.colorTransform(bColor.rect,new ColorTransform(1,1,1,Math.min(1,Math.max(0,alpha)),0,0,0,0))
			
			
			bColor.copyPixels(snap,snap.rect,Geom.point(padding,padding),null,null,true)
			
			return bColor
			
		}			
	}
}
/* commentsOK */