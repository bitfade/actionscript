/*
	determine the alpha>0 region of a display object
*/
package bitfade.utils { 

	public class Crop {
		
		import flash.display.*
		import flash.geom.*
		
		// get alpha > 0 area (Rectangle)
		public static function area(target:*):Rectangle {
			return clip(target,false)
		}
		
		// get alpha > 0 area (BitmapData)
		public static function auto(target:*,p:Point = null):BitmapData {
			return clip(target,true,p)
		}
		
		// do the actual work
		protected static function clip(target:*,autoCrop:Boolean = false,p:Point = null):* {
		
			var bData:BitmapData
			var bTmp:BitmapData
			 
			if (target is BitmapData) {
				bData = target
			} else if (target is Bitmap) {
				bData = target.bitmapData
			} else {
				bTmp = bData = Snapshot.take(target)
			}
		
			var res:Rectangle = bData.getColorBoundsRect(0xFF000000, 0, false)
			
			if (res.width == 0 && res.height == 0) res = bData.rect
			
			if (p) {
				p.x = res.x
				p.y = res.y
			}
			
			if (autoCrop) {
				if (res.x != 0 || res.y != 0 || res.width != bData.width || res.height != bData.height) {
					bTmp = new BitmapData(res.width,res.height,true,0)
					bTmp.copyPixels(bData,res,Geom.origin)
					//bData.dispose()
					bData = bTmp
					
				}
				return bData
			}
			
			if (bTmp) bTmp.dispose()
			
			return res
			
		}
		
		
		
	}
}
/* commentsOK */