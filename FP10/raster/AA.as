package bitfade.FP10.raster {

	public class AA {
	
		public static function line(v:Vector.<uint>,w:uint,x1:uint,y1:uint,x2:uint,y2:uint,color:uint=0xFFFFFFFF) {
		
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-x1 
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
					x2 = x1 + int(u2 * p2);
       				y2 = y1 + int(u2 * p4);						
   	      		}
			}
		
		
			var dx:int
			var dy:int
			var tmp:uint
			var xd:int
			var err:uint
			var errSum:uint
			var eA:uint = 0
			var maxAlpha: uint = color >>> 24
			var mA:Number = Number(maxAlpha)/0xFF
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			color = color & 0xFFFFFF
			
			
   			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;
   			}
   			
   			yp = y1*w+x1
   			
   			eA = (v[yp] >>> 24) + maxAlpha
         	if (eA > 0xFF) eA = 0xFF
         	v[yp] = (eA << 24) | color
   			

   			if ((dx = x2 - x1) >= 0) {
      			xd = 1;
   			} else {
      			xd = -1;
      			dx = -dx; 
   			}
   			
   			// horizontal line
   			if ((dy = y2 - y1) == 0) {
   				yp = y1*w
   			
      			while (dx-- != 0) {
         			x1 += xd;
         			
         			xp = yp+x1
         			
         			eA = (v[xp] >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = (eA << 24) | color
      			}
      			return;
   			}
   			
   			// vertical line
   			if (dx == 0) {
    			do {
         			++y1;
         			
         			yp = y1*w+x1
         			
         			eA = (v[yp] >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			v[yp] = (eA << 24) | color
         			
      			} while (--dy != 0);
      			return;
   			}
   			
   			if (dy > dx) {	
   				err = (dx << 8) / dy;
   				
   				while (--dy) {
         			errSum += err;      
         			if (errSum > 0xFF) {
            			x1 += xd;
            			errSum = errSum & 0xFF
         			}
         			++y1; 
         			yp = y1*w
   					xp = yp+x1
         			
         			
         			eA = (v[xp] >>> 24) + int((errSum ^ 0xFF) >> 4)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = (eA << 24) | color
         			
         			xp = xp+xd
         			
         			eA = (v[xp] >>> 24) + int(errSum >> 4)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = (eA << 24) | color
      			}
      			return;
   			}
   			err = (dy << 8) / dx;
   			
   			yp = y1*w
   			
   			while (--dx) {
   				
   			
      			errSum += err;      /* calculate error for next pixel */
      			if (errSum > 0xFF) {
         			++y1;
         			yp += w
         			errSum = errSum & 0xFF
      			}
      			
      			x1 += xd;
      			xp = yp+x1
      			
      			
      			eA = (v[xp] >>> 24) + int((errSum ^ 0xFF) >> 4)
      			if (eA > 0xFF) eA = 0xFF
      			v[xp] = (eA << 24) | color
      			
      			xp += w
      			
         		eA = (v[xp] >>> 24) + int(errSum >> 4)
         		if (eA > 0xFF) eA = 0xFF
         		v[xp] = (eA << 24) | color
      			
   			}
		}
		
		public static function line2(v:Vector.<uint>,w:uint,x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
		
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-x1 
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
					x2 = x1 + int(u2 * p2);
       				y2 = y1 + int(u2 * p4);						
   	      		}
			}
		
			var dx:int
			var dy:int
			var tmp:uint
			var xd:int
			var err:uint
			var errSum:uint
			var eA:uint = 0
			var maxAlpha: uint = color >>> 24
			var mA:Number = Number(maxAlpha)/0xFF
			
			var xp:uint = 0;
			var yp:uint = 0;
			var alphaMult:uint = 0xFF
			
			color = color & 0xFFFFFF
			
			
   			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;
   			}
   			
   			yp = y1*w+x1
   			
   			eA = (v[yp] >>> 24) + maxAlpha
         	if (eA > 0xFF) eA = 0xFF
         	v[yp] = eA << 24 | color
   			

   			if ((dx = x2 - x1) >= 0) {
      			xd = 1;
   			} else {
      			xd = -1;
      			dx = -dx; 
   			}
   			
   			// horizontal line
   			if ((dy = y2 - y1) == 0) {
   				yp = y1*w
   			
      			while (dx-- != 0) {
         			x1 += xd;
         			
         			xp = yp+x1
         			
         			eA = (v[xp] >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
      			}
   			} else if (dx == 0) {
    			do {
         			++y1;
         			
         			yp = y1*w+x1
         			
         			eA = (v[yp] >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
         			
      			} while (--dy != 0);
   			} else if (dy > dx) {	
   				err = (dx << 8) / dy;
   				
   				while (--dy) {
         			errSum += err;      
         			if (errSum > 0xFF) {
            			x1 += xd;
            			errSum = errSum & 0xFF
         			}
         			++y1; 
         			yp = y1*w
   					xp = yp+x1
         			
         			
         			eA = (v[xp] >>> 24) + ((errSum ^ 0xFF) >> 4)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			xp = xp+xd
         			
         			eA = (v[xp] >>> 24) + (errSum >> 4)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
      			}
   			} else {
				err = (dy << 8) / dx;
				
				yp = y1*w
				
				
				while (--dx) {
					
				
					errSum += err;      /* calculate error for next pixel */
					if (errSum > 0xFF) {
						++y1;
						yp += w
						errSum &= 0xFF
					}
					
					x1 += xd;
					xp = yp+x1
					
					eA = ((v[xp] >>> 24) + ((errSum ^ 0xFF) >> 4))
					if (eA > 0xFF) eA = 0xFF
					v[xp] = eA << 24 | color
					
					
					xp += w
					
					eA = ((v[xp] >>> 24) + (errSum >> 4)) 
					//if (eA > 0xFF) eA = 0xFF
					
					v[xp] = eA << 24 | color
					
					
				}
   			}
   			
		}
		
		


		// draw line from x1,y1 to x2,y2, with specified color, alpha
		// decr is alpha decrement for each iteration
		public static function bres(v:Vector.<uint>,w:uint,x1:int,y1:int,x2:int,y2:int,color:uint,alpha:uint,decr:uint) {
		
			alpha = alpha << 24
			decr = decr << 24
			
			var decr2 = decr << 1
			
			if (alpha < decr2) return
			
			var eA : uint
			
			/*
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-x1 
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
					x2 = x1 + int(u2 * p2);
       				y2 = y1 + int(u2 * p4);						
   	      		}
			}
			*/
			
			// Bresenham's line algorithm 
			var dy:int = (y2 - y1) << 1;
			var dx:int = (x2 - x1) << 1;
   		     	
   		    var stepx:int
			var stepy:int
        	var fraction:int;
     		
     		var xp:uint = 0;
			var yp:uint = 0;
			
			
     		
			if (dy < 0) { dy = -dy;  stepy = -1; } else { stepy = 1; }
			if (dx < 0) { dx = -dx;  stepx = -1; } else { stepx = 1; }
			
			
       		if (dx > dy) {
				fraction = (dy << 1) -dx
				while (x1 != x2) {
					if (fraction >= 0) {
						y1 += stepy;
						fraction -= dx;
					}
					x1 += stepx;
					fraction += dy;
					if (alpha < decr2) break
					alpha -= decr
					yp = y1*w+x1
						
					eA = (v[yp] >> 24) + (alpha >> 24) 
					eA = (eA < 0xFF) ? eA << 24 : 0xFF000000
					v[yp] = color | eA
					
				}
			} else {
				return
				fraction = dx-(dy << 1);
				while (y1 != y2) {
					if (fraction >= 0) {
						x1 += stepx;
						fraction -= dy;
					}
					y1 += stepy;
					fraction += dx;
					if (alpha < decr2) break
					alpha -= decr
					yp = y1*w+x1
					
					eA = (v[yp] >> 24) + (alpha >> 24) 
					eA = (eA < 0xFF) ? eA << 24 : 0xFF000000
					v[yp] = color | eA
				}
			}
			
		
		}
		
		
	}
}
	