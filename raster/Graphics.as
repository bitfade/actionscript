/*

	this class is used for heavy weight direct bitmap drawing

*/
package bitfade.raster {

	public class Graphics {
	
		public var target:Vector.<uint>
		public var width:uint = 0
		public var height:uint = 0
				
		public var clippedX:int
		public var clippedY:int
		
		public var clippedX1:int
		public var clippedY1:int
			
		// clip a line so that it doesn't cross his bounding box
		public function clip(x1:int,y1:int,x2:int,y2:int) {
			
			// Liang - Barsky Line Clipping Algorithm
			var u1:Number = 0
			var u2:Number = 1
			var p1:Number = x1-x2
			var p2:Number = x2-x1
			var p3:Number = y1-y2
			var p4:Number = y2-y1
				
			var q1:Number = x1
			var q2:Number = width-1-x1 
			var q3:Number = y1
			var q4:Number = height-1-y1
				
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
					clippedX1 = x1 + int(u1 * p2) ;
					clippedY1 = y1 + int(u1 * p4) ;
					
					clippedX = x1 + int(u2 * p2);
       				clippedY = y1 + int(u2 * p4);
       										
   	      		}
			}
		}		
	}
}
/* commentsOK */	