/*
	analyze a bitmapData and return a linked list of points
*/
package bitfade.utils { 

	public class BitmapPoints {
		
		import flash.display.*
		import flash.geom.*
		import flash.display.*
		import flash.filters.*
		
		import bitfade.data.*
		import bitfade.data.geom.*
		
		// get bitmap edges as a linked list of points
		public static function getEdges(target:BitmapData,queue:LinkedListPool,maxNodes:uint = 5000):void {
  		
  			var tmp:BitmapData = new BitmapData(target.width+1,target.height+1,true,0)
  			
  			// smooth the image, so we get less points for small texts
  			tmp.applyFilter(target,target.rect,Geom.origin,new DropShadowFilter(0,0,0xFF0000,1,2,2,0.7,1,false,false,true))

  			var count: uint = 0
  			
  			var maxW:uint = target.width
  			var maxH:uint = target.height
  			var xp:uint,yp:uint,p:uint = 0
  			var current:uint = 0
  			
  			var fill:Boolean
  			var alphaOk:Boolean
  			
  			var precision: uint = 1
  			
  			var node:Point2d
  			
  			// vertical pass
  			for (yp = 0;yp<maxH;yp += precision) {
  				fill = false
  				for (xp = 0;xp<maxW;xp += precision) {
  					alphaOk = tmp.getPixel32(xp,yp) > 0x80000000
  					
  					if (alphaOk != fill) {
  						fill = !fill
  						tmp.setPixel32(xp,yp,0xFFFFFFFF)
  						
  						//node = new point2d()
  						node = queue.create()
  						
  						node.x = xp
  						node.y = yp
  						queue.append(node)
  					}
  				}
  			}
  			
  			// horizontal pass
  			for (xp = 0;xp<maxW;xp += precision) {
  				fill = false
  				for (yp = 0;yp<maxH;yp += precision) {
  					current = tmp.getPixel32(xp,yp)
  					if (current & 0xFF) continue
  					alphaOk = current  > 0x80000000
  					
  					if (alphaOk != fill) {
  						fill = !fill
  						
  						node = queue.create()
  						//node = new point2d()
  						node.x = xp
  						node.y = yp
  						queue.append(node)
  					}
  				}
  			}
  			
  			// if we have to much nodes, delete some
  			if (queue.length > maxNodes) {
  				var incr:Number = (queue.length-maxNodes+1) / queue.length
  				var pos:Number = 0
  				 				
  				queue.rewind()
			
				while (node = queue.next) {
					pos += incr
					if (pos > 1) {
						pos--
						queue.deleteCurrent()
					}
				}
  				
			}
  			
  		}
		
	}
}
/* commentsOK */