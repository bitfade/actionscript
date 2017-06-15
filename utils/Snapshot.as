/*
	this are function used take snapshots (bitmapData)
*/
package bitfade.utils { 

	public class Snapshot {
		
		import flash.display.*
		import flash.geom.Matrix
		
		// take a snapshot of a display Object
		public static function take(target:*,bMap:* = null,w:uint=0,h:uint=0,mat:Matrix = null):BitmapData {
			var bData:BitmapData
			var output:BitmapData
			
			var tw:uint = w > 0 ? w : target.width
			var th:uint = h > 0 ? h : target.height
			
			// check if an existing bMap is supplied
			if (bMap) {
				output = bMap is BitmapData ? bMap : Bitmap(bMap).bitmapData
				
				if (output) {
					if (mat || (output.width == tw && output.height == th) ) {
						// reuse bitmapData
						bData = output
						bData.fillRect(bData.rect,0)
					} else {
						// remove old bitmapData
						output.dispose()
					}
				}
				
			} 
			
			
			if (!mat && (target is Bitmap || target is BitmapData)) {
				// don't draw if target is already a bitmapData
				bData = target is BitmapData ? BitmapData(target) : Bitmap(target).bitmapData
			} else {
				
				if (mat) {
				
					// TO BE CHECKED
					tw = mat.a > 1 ? Math.min(tw,uint(tw*mat.a)) : tw
					th = mat.d > 1 ? Math.min(th,uint(th*mat.d)) : th
					
					//tw = uint(tw*mat.a)
					//th = uint(th*mat.d)
									
				}
				
				if (!bData) bData = new BitmapData(tw,th,true,0)
			
				if (target is Bitmap) Bitmap(target).smoothing = true
			
				bData.draw(target,mat,null,null,null,true)
			
			}
			
			
			if (bMap && bMap is Bitmap) bMap.bitmapData = bData
			
			return bData
			
		} 		
	}
}
/* commentsOK */