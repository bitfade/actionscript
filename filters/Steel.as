/*

	Steel bitmapData filter

*/
package bitfade.filters {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	
	import bitfade.utils.*
	import bitfade.easing.*
	
	public class Steel extends bitfade.filters.Filter {
	
		public static function apply(target:DisplayObject):BitmapData {
		
			var snap:BitmapData = Snapshot.take(target)
		
		
			if (!(target is Bitmap && Bitmap(target).bitmapData === snap) ) {
				Gc.destroy(target)
			}
			
			var w:uint = target.width
			var h:uint = target.height
			
			
			var bColor:BitmapData = Bdata.create(w,h)
			var bBuffer:BitmapData = bColor.clone()
			var bBuffer2:BitmapData = bColor.clone()
			
			
			var box:Rectangle = bColor.rect
			
			
			// some stuff needed
			var r = new Rectangle(0,0,w,1)
			var minI:uint = 0
			var maxI:uint = 0xFF
			var idx:uint = 0
			var h2:uint = h >> 1
			
			// draw the color mask
			for (var yp:uint=0;yp<h;yp++) {
				r.y = yp
				idx = (yp <= h2) ? bitfade.easing.Quad.Out(yp,minI,maxI-minI,h2) : bitfade.easing.Quad.In(yp-h2,maxI,minI-maxI,h2)
				
				bBuffer2.fillRect(r,(idx << 24))
				
			}
			
			bBuffer2.paletteMap(bBuffer2,box,Geom.origin,null,null,null,Colors.buildColorMap("steel",0xFF))
			
			bColor.copyPixels(bBuffer2,box,Geom.origin,snap,Geom.origin)
			
			
			bBuffer2.noise(1,0,0xFF,7, true)
			bBuffer.applyFilter(bBuffer2,box,Geom.origin,new BlurFilter(8,4,2))
			
			
			bBuffer2.copyPixels(bBuffer,box,Geom.origin,snap,Geom.origin)
			
			bBuffer.applyFilter(bBuffer2,box,Geom.origin,new GlowFilter(0,1,2,2,2,1,true))
			
			bColor.draw(bBuffer,null,new ColorTransform(1,1,1,1,0,0,0,0),"subtract",null,true)
		
			bColor.draw(snap,null,new ColorTransform(1,1,1,1,0,0,0,0),"overlay",null,true)
			
			
			bBuffer = Gc.destroy(bBuffer)
			bBuffer2 = Gc.destroy(bBuffer2)
			
			return bColor
			
		}			
	}
}
/* commentsOK */