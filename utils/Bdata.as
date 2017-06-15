/*
	some handy bitmapData functions 
*/
package bitfade.utils { 

	public class Bdata {
		
		import flash.display.*
		import flash.geom.*
		import flash.display.*
		import flash.filters.*
		
		
		// create a bitmapData
		public static function create(w:uint,h:uint,existing:BitmapData = null):BitmapData {
			if (existing) {
				if (existing.width == w && existing.height == h) {
					return existing
				} 
				existing.dispose()
			}
  		
  			return new BitmapData(w,h,true,0)
  		}
		
	}
}
/* commentsOK */