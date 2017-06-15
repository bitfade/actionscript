package bitfade.display {

	import flash.display.BitmapData;
	import flash.geom.*;
	import org.osflash.thunderbolt.Logger
	
	public class ExtBitmapDataV2 extends BitmapData {
	
		public var lastX:Number = 0
		public var lastY:Number = 0
		
		protected static var mask:BitmapData
		
		protected var maskR:Rectangle
		protected var p:Point
	
		public function ExtBitmapDataV2(width:int, height:int, transparent:Boolean = true, fillColor:uint = 0xFFFFFFFF) {
			super(width,height,transparent,fillColor)
			if (!mask) {
				 mask = new BitmapData(32,32,true,0)
			}
			maskR = new Rectangle()
			p = new Point()
		}
		
		public function moveTo(x1:Number,y1:Number) {
			lastX = x1
			lastY = y1
		}
		
		public function curveTo(x1:Number,y1:Number) {
			var step:uint = 512
			var dx:Number = (x1-lastX)/step
			var dy:Number = (y1-lastY)/step
			
			maskR.width = 8
			maskR.height = 8
			
			for (var i:uint=1; i<step; i++) {
				lastX += dx
				lastY += dy
				p.x = uint(lastX + 0.5)
				p.y = uint(lastY + 0.5) 
				mask.fillRect(maskR,((0x10 ) << 24) + 0xFFFFFF)
				copyPixels(mask,maskR,p,null,null,true)
			}
		}
		
		public function wuLine(x1:uint,y1:uint,x2:uint,y2:uint,color:uint=0xFFFFFFFF) {
			var dx:int
			var dy:int
			var tmp:uint
			var xd:int
			var err:uint
			var errSum:uint
			var eA:uint = 0
			var maxAlpha: uint = color >>> 24
			var mA:Number = Number(maxAlpha)/0xFF
			
			color = color & 0xFFFFFF
			
			
   			if (y1 > y2) {
     			tmp = y1; y1 = y2; y2 = tmp;
      			tmp = x1; x1 = x2; x2 = tmp;
   			}
   			
   			eA = (getPixel32(x1,y1) >>> 24) + maxAlpha
         	if (eA > 0xFF) eA = 0xFF
         	setPixel32(x1,y1,(eA << 24) | color)
   			

   			if ((dx = x2 - x1) >= 0) {
      			xd = 1;
   			} else {
      			xd = -1;
      			dx = -dx; 
   			}
   			
   			// horizontal line
   			if ((dy = y2 - y1) == 0) {
      			while (dx-- != 0) {
         			x1 += xd;
         			
         			eA = (getPixel32(x1,y1) >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			setPixel32(x1,y1,(eA << 24) | color)
      			}
      			return;
   			}
   			
   			// vertical line
   			if (dx == 0) {
    			do {
         			y1++;
         			
         			eA = (getPixel32(x1,y1) >>> 24) + maxAlpha
         			if (eA > 0xFF) eA = 0xFF
         			setPixel32(x1,y1,(eA << 24) | color)
         			
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
         			y1++; 
         			
         			eA = (getPixel32(x1,y1) >>> 24) + uint((errSum ^ 0xFF)*mA)
         			if (eA > 0xFF) eA = 0xFF
         			setPixel32(x1,y1,(eA << 24) | color)
         			eA = (getPixel32(x1+xd,y1) >>> 24) + uint(errSum*mA)
         			if (eA > 0xFF) eA = 0xFF
         			setPixel32(x1+xd,y1,(eA << 24) | color)
         			
      			}
      			return;
   			}
   			err = (dy << 8) / dx;
   			while (--dx) {
      			errSum += err;      /* calculate error for next pixel */
      			if (errSum > 0xFF) {
         			y1++;
         			errSum = errSum & 0xFF
      			}
      			
      			x1 += xd;
      			
      			
      			eA = (getPixel32(x1,y1) >>> 24) + uint((errSum ^ 0xFF)*mA)
      			if (eA > 0xFF) eA = 0xFF
         		setPixel32(x1,y1,(eA << 24) | color)
         		eA = (getPixel32(x1,y1+1) >>> 24) + uint(errSum*mA)
         		if (eA > 0xFF) eA = 0xFF
         		setPixel32(x1,y1+1,(eA << 24) | color)
         		
      			
   			}
		}

		
		
		
		
	}
}
	