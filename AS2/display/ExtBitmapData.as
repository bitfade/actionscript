/*
	This class extends flash.display.BitmapData by adding a line drawing method
*/

	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	class bitfade.AS2.display.ExtBitmapData extends BitmapData {
		public function ExtBitmapData(width:Number, height:Number, transparent:Boolean, fillColor:Number) {
			super(width,height,transparent,fillColor)
		}
		
		
		
		// draw line from x1,y1 to x2,y2, with specified color, alpha
		// decr is alpha decrement for each iteration
		public function line(x1:Number,y1:Number,x2:Number,y2:Number,color:Number,alpha:Number,decr:Number) {
		
		
			alpha = alpha << 24
			decr = decr << 24
			
			var decr2 = decr << 1
			
			if (alpha < decr2) return
			
			var eA : Number
			/*
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = width-x1 
			var q3:Number = y1
			var q4:Number = height-y1
				
			var r1:Number = 0
			var r2:Number = 0
			var r3:Number = 0
			var r4:Number = 0
			
			
			if (	(p1 == 0 && q1 < 0) || 
					(p2 == 0 && q2 < 0) ||
					(p3 == 0 && q3 < 0) ||
					(p4 == 0 && q4 < 0) 
				) {
			} else {
				
				if( p1 != 0 ) {
					r1 = q1/p1 ;
           	 		if( p1 < 0 )
           	 			u1 = r1 > u1 ? r1 : u1 
           	 		else 
           	 			u2 = r1 < u2 ? r1 : u2
     			}
   	     			
     			if( p2 != 0 ) {
           		 	r2 = q2/p2 ;
           	 		if( p2 < 0 ) 
           	 			u1 = r2 > u1 ? r2 : u1 
           	 		else 
           	 			u2 = r2 < u2 ? r2 : u2
     			}
   	     			
     			if( p3 != 0 ) {
           		 	r3 = q3/p3 ;
           	 		if( p3 < 0 ) 
           	 			u1 = r3 > u1 ? r3 : u1 
           	 		else 
           	 			u2 = r3 < u2 ? r3 : u2;
     			} 
   	     			
     			if( p4 != 0 ) {
           		 	r4 = q4/p4 ;
           	 		if( p4 < 0 ) 
          	 			u1 = r4 > u1 ? r4 : u1 
           	 		else 
          	 			u2 = r4 < u2 ? r4 : u2;
     			}
				
					
				if( u1 <= u2 ) {
					x2 = int(x1 + (u2 * p2));
       				y2 = int(y1 + (u2 * p4));						
   	      		}
			}
			*/
			// Bresenham's line algorithm 
			var dy:Number = (y2 - y1)*2;
			var dx:Number = (x2 - x1)*2;
   		     	
   		    var stepx:Number
			var stepy:Number
        	var fraction:Number;
        	//var count:Number = 0;
        	
			if (dy < 0) { dy = -dy;  stepy = -1; } else { stepy = 1; }
			if (dx < 0) { dx = -dx;  stepx = -1; } else { stepx = 1; }
			
			
			if (dx > dy) {
				fraction = (dy*2) -dx
				while (x1 != x2) {
					if (fraction >= 0) {
						y1 += stepy;
						fraction -= dx;
					}
					x1 += stepx;
					fraction += dy;
					if (alpha < decr2) break
					alpha -= decr
					setPixel32(x1,y1,alpha)
					//if (++count > 50) return
					/*
					alpha -= decr
					eA = (getPixel32(x1,y1) >> 24) + (alpha >> 24) 
					eA = (eA < 0xFF) ? eA << 24 : 0xFF000000
					setPixel32(x1,y1,color | eA)
					*/
					
				}
			} else {
				fraction = dx-(dy*2);
				while (y1 != y2) {
					if (fraction >= 0) {
						x1 += stepx;
						fraction -= dy;
					}
					y1 += stepy;
					fraction += dx;
					if (alpha < decr2) break
					alpha -= decr
					setPixel32(x1,y1,alpha)
					//if (++count > 50) return
					/*
					alpha -= decr
					eA = (getPixel32(x1,y1) >> 24) + (alpha >> 24) 
					eA = (eA < 0xFF) ? eA << 24 : 0xFF000000
					setPixel32(x1,y1,color | eA)
					*/
				}
			}
			
		
		}		
		
	}
	