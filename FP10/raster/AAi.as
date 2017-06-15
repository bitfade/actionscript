package bitfade.FP10.raster {

	public final class AAi {
	
		
		public var bitV:Vector.<uint>
		public var width:uint = 0
		public var height:uint = 0
		public var alphas:Vector.<uint>
		
		
		public function line(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			
			var v:Vector.<uint> = bitV
			
			color = color & 0xFFFFFF
			
			yp = y1*w+x1
			
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
					if (eA > 0xFF) eA = 0xFF
					
					v[xp] = eA << 24 | color
					
					
				}
   			}
   			
		}
		
		import flash.geom.Point
		public function clip(x1:int,y1:int,x2:int,y2:int,p:Point) {
		
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
			var r1:Number = 0
			var r2:Number = 0
			var r3:Number = 0
			var r4:Number = 0
			
			p.x = x2
			p.y = y2
			
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
					p.x = x1 + int(u2 * p2);
       				p.y = y1 + int(u2 * p4);						
   	      		}
			}
		
		}
		
		public function line2(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var div:int = (1 << 16)/0xFF
			var mA:int = maxAlpha*div
			var decr:int = 0
			var inv:Boolean = false;
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			var v:Vector.<uint> = bitV
			
			
			color = color & 0xFFFFFF
			
			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;
      			inv = true
      			
   			} else {
   				yp = y1*w+x1
   			
   				eA = (v[yp] >>> 24) + (maxAlpha*mA >> 16)
         		if (eA > 0xFF) eA = 0xFF
         		v[yp] = eA << 24 | color
      			//mA = 0
   			}
   			
   		
   			

   			if ((dx = x2 - x1) >= 0) {
      			xd = 1;
   			} else {
      			xd = -1;
      			dx = -dx; 
   			}
   			
   			// horizontal line
   			if ((dy = y2 - y1) == 0) {
   				yp = y1*w
   				
   				decr = -mA/dx
   			
      			while (dx-- != 0) {
         			x1 += xd;
         			
         			xp = yp+x1
         			
         			eA = (v[xp] >>> 24) + (maxAlpha*mA >> 16)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			mA += decr
					//if (mA < decr) return
      			}
   			} else if (dx == 0) {
   				if (inv) {
   					decr = mA/dy
   					mA = 0
   				} else {
   					decr = -mA/dy
   				}
   				do {
         			++y1;
         			
         			yp = y1*w+x1
         			
         			eA = (v[yp] >>> 24) + (maxAlpha*mA >> 16)
         			if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
         			
         			mA += decr
					//if (mA < decr) return
         			
      			} while (--dy != 0);
   			} else if (dy > dx) {	
   				err = (dx << 8) / dy;
   				if (inv) {
   					decr = mA/dy
   					mA = 0
   				} else {
   					decr = -mA/dy
   				}
   				while (--dy) {
         			errSum += err;      
         			if (errSum > 0xFF) {
            			x1 += xd;
            			errSum = errSum & 0xFF
         			}
         			++y1; 
         			yp = y1*w
   					xp = yp+x1
         			
         			
         			eA = (v[xp] >>> 24) + ((errSum ^ 0xFF)*mA >> 16) 
					if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			xp = xp+xd
         			
         			eA = (v[xp] >>> 24) + (errSum*mA >> 16)
					if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			mA += decr
         			
      			}
   			} else {
				err = (dy << 8) / dx;
				
				yp = y1*w
				
				if (inv) {
   					decr = mA/dx
   					mA = 0
   				} else {
   					decr = -mA/dx
   				}
				while (--dx) {
					
					errSum += err;      
					if (errSum > 0xFF) {
						++y1;
						yp += w
						errSum &= 0xFF
					}
					
					x1 += xd;
					xp = yp+x1
					
					eA = (v[xp] >>> 24) + ((errSum ^ 0xFF)*mA >> 16) 
					if (eA > 0xFF) eA = 0xFF
					
					v[xp] = eA << 24 | color
					
					
					xp += w
					
					eA = (v[xp] >>> 24) + (errSum*mA >> 16)
					if (eA > 0xFF) eA = 0xFF
					
					v[xp] = eA << 24 | color
					
					mA += decr
					
				}
   			}
   			
		}
		
		public function line3(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var div:int = (1 << 16)
			var mA:int = maxAlpha*div
			var decr:int = 0
			var inv:Boolean = false;
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			
			var v:Vector.<uint> = bitV
			
			
			color = color & 0xFFFFFF
			
			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;
      			inv = true
      			
   			} else {
   				yp = y1*w+x1
   			
   				eA = (v[yp] >>> 24) + (mA >> 16)
         		if (eA > 0xFF) eA = 0xFF
         		v[yp] = eA << 24 | color
      			//mA = 0
   			}
   			
   		
   			

   			if ((dx = x2 - x1) >= 0) {
      			xd = 1;
   			} else {
      			xd = -1;
      			dx = -dx; 
   			}
   			
   			// horizontal line
   			if ((dy = y2 - y1) == 0) {
   				yp = y1*w
   				
   				decr = -mA/dx
   			
      			while (dx-- != 0) {
         			x1 += xd;
         			
         			xp = yp+x1
         			
         			eA = (v[xp] >>> 24) + (mA >> 16)
         			if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			mA += decr
      			}
   			} else if (dx == 0) {
   				if (inv) {
   					decr = mA/dy
   					mA = 0
   				} else {
   					decr = -mA/dy
   				}
   				do {
         			++y1;
         			
         			yp = y1*w+x1
         			
         			eA = (v[yp] >>> 24) + (mA >> 16)
         			if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
         			
         			mA += decr
         			
      			} while (--dy != 0);
   			} else if (dy > dx) {	
   				err = (dx << 8) / dy;
   				if (inv) {
   					decr = mA/dy
   					mA = 0
   				} else {
   					decr = -mA/dy
   				}
   				while (--dy) {
         			errSum += err;      
         			if (errSum > 0xFF) {
            			x1 += xd;
            			errSum = errSum & 0xFF
         			}
         			++y1; 
         			yp = y1*w
   					xp = yp+x1
         			
         			
         			eA = (v[xp] >>> 24) + (mA >> 16) 
					if (eA > 0xFF) eA = 0xFF
         			v[xp] = eA << 24 | color
         			
         			
         			mA += decr
         			
      			}
   			} else {
				err = (dy << 8) / dx;
				
				yp = y1*w
				if (inv) {
   					decr = mA/dx
   					mA = 0
   				} else {
   					decr = -mA/dx
   				}
				while (--dx) {
					
					errSum += err;      
					if (errSum > 0xFF) {
						++y1;
						yp += w
						errSum &= 0xFF
					}
					
					x1 += xd;
					xp = yp+x1
					
					eA = (v[xp] >>> 24) + (mA >> 16) 
					if (eA > 0xFF) eA = 0xFF
					
					v[xp] = eA << 24 | color
					
					
					
					
					mA += decr
					
				}
   			}
   			
		}
		
		public function line4(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var div:int = (1 << 16)
			var mA:int = maxAlpha
			var decr:int = 0
			var inv:Boolean = false;
			var max2:uint = 0xFF
			
			
			var xp:uint = 0;
			var yp:uint = 0;
			
			var v:Vector.<uint> = bitV
			
			
			color = color & 0xFFFFFF
			
			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;      			
   			} 
   			
   			yp = y1*w+x1
   			
   			eA = (v[yp] >>> 24) + maxAlpha
         	if (eA > max2) eA = max2
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
         			if (eA > max2) eA = max2
         			v[xp] = eA << 24 | color
         			
         			mA += decr
      			}
   			} else if (dx == 0) {
   				do {
         			++y1;
         			
         			yp = y1*w+x1
         			
         			eA = (v[yp] >>> 24) + maxAlpha
         			if (eA > max2) eA = max2
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
         			
         			
         			eA = (v[xp] >>> 24) + maxAlpha 
					if (eA > max2) eA = max2
         			v[xp] = eA << 24 | color
         			
         		
         			
      			}
   			} else {
				err = (dy << 8) / dx;
				
				yp = y1*w
				
				while (--dx) {
					
					errSum += err;      
					if (errSum > 0xFF) {
						++y1;
						yp += w
						errSum &= 0xFF
					}
					
					x1 += xd;
					xp = yp+x1
					
					eA = (v[xp] >>> 24) + maxAlpha 
					if (eA > max2) eA = max2
					
					v[xp] = eA << 24 | color
	
					
				}
   			}
   			
		}
		
		public function myline(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
		
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var adx:int
			var ady:int
			
			var yp:uint
			var eA:uint
			var err:int
   			
			var incr:int
			var other:int
			
			var sp:int
			var last:int
			
			var v:Vector.<uint> = bitV
			
			dx = x2-x1
			dy = y2-y1
			
			adx = (dx ^ (dx >> 31)) - (dx >> 31);
			ady = (dy ^ (dy >> 31)) - (dy >> 31);
			//s = 
			
			color = color & 0xFFFFFF
			
			//yp = (y1-1)*w+x1
			//v[yp] = 0xFF000000| color	
   			
			if (ady > adx) {
				x1++
			
				dx = dx << 8
				dx = dx / ady
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
				last = x1
				
   				x1 <<= 8
   				
   				//x1 += dx
   				
   				var count:uint = 0
   				
   				for (;ady != 0; --ady,yp += sp,x1 += dx) {
   				
					err = x1 >>> 8
					
					if (err != last) {
						yp += incr
						last = err
					}
				
					/*
					eA = v[yp] >>> 24
					if (eA == 0xFF) continue
					eA += maxAlpha
					if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
					*/
					
					eA = v[yp] >>> 24
					//if (eA == 0xFF) continue
					eA += x1 & 0xFF
					if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
					
					other = yp-1
					
					eA = v[other] >>> 24
					if (eA == 0xFF) continue
					eA += (x1 & 0xFF) ^ 0xFF
					if (eA > 0xFF) eA = 0xFF
         			v[other] = eA << 24 | color
         			
         			
					
				
				}
			} else {
				
				y1++
				
				dy = dy << 8
				dy = dy / adx	
				
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
   				last = y1
   				
   				y1 <<= 8
   				
 				for (;adx != 0; --adx, y1 += dy,yp += incr) {
 					
					err = y1 >>> 8
					
					if (err != last) {
						yp += sp
						last = err
					}
				
					
					
					/*
					eA = v[yp] >>> 24
					if (eA == 0xFF) continue
					eA += maxAlpha
					if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
					*/
					
					
					eA = v[yp] >>> 24
					//if (eA == 0xFF) continue
					eA += y1 & 0xFF
					if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24 | color
					
					other = yp-w
					
					eA = v[other] >>> 24
					if (eA == 0xFF) continue
					eA += (y1 & 0xFF) ^ 0xFF
					if (eA > 0xFF) eA = 0xFF
         			v[other] = eA << 24 | color
         			
					
				
				}
			
				
			}
			
			
   			
		}
		
		public function myline2(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var adx:int
			var ady:int
			
			var yp:uint
			var eA:uint
			var nA:uint
			var err:int
   			
			var incr:int
			var other:int
			
			var sp:int
			var last:int
			
			var maxAlpha: uint = color >>> 24
			var mA:int = maxAlpha*(1 << 16)/0xFF
			var decr:int = 0
			
			var v:Vector.<uint> = bitV
			
			dx = x2-x1
			dy = y2-y1
			
			adx = (dx ^ (dx >> 31)) - (dx >> 31);
			ady = (dy ^ (dy >> 31)) - (dy >> 31);
			//s = 
			
			color = color & 0xFFFFFF
			
			//yp = (y1-1)*w+x1
			//v[yp] = 0xFF000000| color	
   			
			if (ady > adx) {
			
				decr = -mA/ady
			
				x1++
			
				dx = dx << 8
				dx = dx / ady
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
				last = x1
				
   				x1 <<= 8
   				
   				var count:uint = 0
   				
   				for (;ady != 0; --ady,yp += sp,x1 += dx, mA += decr) {
   				
					err = x1 >>> 8
					
					if (err != last) {
						yp += incr
						last = err
					}
				
					eA = v[yp] 
					eA >>>= 24
					nA = x1 
					nA &= 0xFF
					nA *= mA 
					nA >>= 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF
					
					eA <<= 24
					eA |= color
         			v[yp] = eA 
					
					other = yp-1
					
					eA = v[other] 
					eA >>>= 24
					nA = x1 
					nA &= 0xFF
					nA ^= 0xFF
					nA *= mA 
					nA >>= 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF
					
					eA <<= 24
					eA |= color
         			v[other] = eA
         			
					
				
				}
			} else {
				decr = -mA/adx
				
				y1++
				
				dy = dy << 8
				dy = dy / adx	
				
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
   				last = y1
   				
   				y1 <<= 8
   				
 				for (;adx != 0; --adx, y1 += dy,yp += incr,mA += decr) {
 					
					err = y1 >>> 8
					
					if (err != last) {
						yp += sp
						last = err
					}
				
					eA = v[yp] 
					eA >>>= 24
					nA = y1 
					nA &= 0xFF 
					nA *= mA 
					nA >>= 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF
					
					eA <<= 24
					eA |= color
         			v[yp] = eA 
					
					other = yp-w
					
					eA = v[other]
					eA >>>= 24
					nA = y1 
					nA &= 0xFF 
					nA ^= 0xFF
					nA *= int(mA) 
					nA >>= 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF
					
					eA <<= 24
					eA |= color
         			v[other] = eA 
         			
				
				}
			
				
			}
			
			
   			
		}
		
		public function myline3(x1:int,y1:int,x2:int,y2:int,color:uint=0xFFFFFFFF) {
			
			var w:uint = width
			var h:uint = height
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = w-1-x1 
			var q3:Number = y1
			var q4:Number = h-1-y1
				
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
			var adx:int
			var ady:int
			
			var yp:uint
			var eA:uint
			var nA:uint
			var err:int
   			
			var incr:int
			var other:int
			
			var sp:int
			var last:int
			
			var maxAlpha: uint = color >>> 24
			var mA:int = maxAlpha*(1 << 16)/0xFF
			var decr:int = 0
			
			var v:Vector.<uint> = bitV
			
			dx = x2-x1
			dy = y2-y1
			
			adx = (dx ^ (dx >> 31)) - (dx >> 31);
			ady = (dy ^ (dy >> 31)) - (dy >> 31);
			//s = 
			
			color = color & 0xFFFFFF
			
			//yp = (y1-1)*w+x1
			//v[yp] = 0xFF000000| color	
   			
			if (ady > adx) {
			
				decr = -mA/ady
			
				x1++
			
				dx = dx << 8
				dx = dx / ady
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
				last = x1
				
   				x1 <<= 8
   				
   				var count:uint = 0
   				
   				for (;ady != 0; --ady,yp += sp,x1 += dx, mA += decr) {
   				
					err = x1 >>> 8
					
					if (err != last) {
						yp += incr
						last = err
					}
				
					eA = v[yp] >>> 24
					nA = 0xFF*mA >> 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF					
         			v[yp] = eA << 24 
					
         			
					
				
				}
			} else {
				
				decr = -mA/adx
				
				y1++
				
				dy = dy << 8
				dy = dy / adx	
				
				
				yp = y1*w+x1
   				
				sp = y1 > y2 ? -w : w
				incr = x1 > x2 ? -1 : 1
				
   				last = y1
   				
   				y1 <<= 8
   				
 				for (;adx != 0; --adx, y1 += dy,yp += incr,mA += decr) {
 					
					err = y1 >>> 8
					
					if (err != last) {
						yp += sp
						last = err
					}
				
					eA = v[yp] >>> 24
					nA = 0xFF*mA >> 16
					eA += nA
					if (eA > 0xFF) eA = 0xFF
         			v[yp] = eA << 24
					
					
         			
				
				}
			
				
			}
			
			
   			
		}
		
		
	}
}
	