import flash.display.*
import flash.geom.*
import flash.filters.DropShadowFilter

import bitfade.AS2.display.ExtBitmapData

class bitfade.AS2.intro.light extends bitfade.AS2.intro.base {
		
	// light box variables
	private var lPos:Number;
	private var lIncr:Number;
	private var lMin:Number;
	private var lMax:Number;
	
	// drop shadow filter
	private var dsF;
	
	private var hb:Array;
		
	// used to draw lines
	private var bBuffer2:ExtBitmapData;
	private var bLine:BitmapData;
	
		
	public function light(opts:Object){
		super(opts)		
	}
		
	public function localInit() {
	
		bBuffer2 = new ExtBitmapData(w,h,true,0);
		bLine = bData.clone();
		
		// create the filter
		dsF = new DropShadowFilter(w,0,0,1,8,8,1.8,2,false,false,false)
		//dsF = new DropShadowFilter(w,0,0,1,8,8,5,2,false,false,false)
		
		lMax = hitR.width*2+pt.x
		lMin = pt.x-hitR.width
			
		lPos = lMin
						
		lIncr = 5
		
		hb = new Array();
		
		var xp:Number
		var yp:Number
			
		var xm:Number = hitR.width 
		var ym:Number = hitR.height
		
		var searchBoxSize:Number = 32
		
		var r = new Rectangle(0,0,searchBoxSize,searchBoxSize)
		
		for (xp = 0;xp<xm;xp += searchBoxSize) {
			r.x = xp
						
			for (yp = 2;yp<ym;yp += searchBoxSize) {
				r.y = yp
				if (bDraw.hitTest(origin,0x01,r)) {
					hb[yp*2048+xp] = true;
				}
			
			}
		}
		
		
	}
		
	public static function create(canvas,opts) {
		opts.canvas = canvas
		return new light(opts)
	}
	
	public function update() {
	
		// some variables used to move the light box
		var xp:Number
		var yp:Number
			
		var xs:Number = int(pt.x)
		var ys:Number = int(pt.y)
			
		var xm:Number = hitR.width 
		var ym:Number = hitR.height
		
		var xc:Number = Math.round(w/2)
		var yc:Number = Math.round(h/2)
		
		
		
		var x1:Number
		var x2:Number
		var y1:Number
		var y2:Number
		
		
		var sA:Number = 0
		var av:Number = 0
		
		var dx:Number
		var dy:Number
		
		var xi:Number
		var yi:Number
		
		var step:Number
		var i:Number;
		
		var searchBoxSize:Number = 32
		
		// clear stuff
		bBuffer2.fillRect(box,0)
		
		
		// now, for every 4x4 box which contains pixels with alpha > 0, cast rays
		for (xp = 0;xp<xm;xp += searchBoxSize) {
						
			
			x1 = xs+xp+16
			x2 = x1+(x1-lPos)*16
			
			sA = int((xm-Math.min(Math.abs(x1-lPos),xm))*0x80/xm)
			
			if (Math.abs(x2-x1)< 32) {
				x2 += (x1<x2) ? 16 : -16
			} 
			
			if (sA > 20)
			for (yp = 2;yp<ym;yp += searchBoxSize) {
			
				if (hb[yp*2048+xp]) {
					
					
					
					y1 = ys+yp
			
					y2 = y1+(y1-yc)*10
					
					dx = (x2 - x1);	
					dy = (y2 - y1);
					
					
					/*
					
					av = sA * 0x1000000
			
					
					step =  Math.max(Math.abs(dx),Math.abs(dy))
					
					xi = dx/step;
					yi = dy/step;
					
					for(i=0;i<step;i++) {
						if (av < 0x02000000 || x1 > w || y1 > h || x1 < 0 || y1 < 0) break;
						bBuffer2.setPixel32(int(x1),int(y1),0xFF000000)
						av -= 0x1000000
						x1+=xi;
						y1+=yi;
						
					}
					*/
					//bBuffer2.copyPixels(bLine,new Rectangle(0,0,50,50),new Point(x1,y1),null,null,true)
					bBuffer2.line(x1,y1,x2,y2,0,sA,1)
					
				}
			
			}
		}
		
		bBuffer2.copyPixels(bBuffer2,box,new Point(0,1),null,null,true)
		bBuffer2.copyPixels(bBuffer2,box,new Point(0,2),null,null,true)
		
		bBuffer2.copyPixels(bBuffer2,box,new Point(0,16),null,null,true)
		bBuffer2.copyPixels(bBuffer2,box,new Point(16,0),null,null,true)
		//bBuffer2.copyPixels(bBuffer2,box,new Point(4,0),null,null,true)
		//bBuffer2.copyPixels(bBuffer2,box,new Point(2,0),null,null,true)
		//bBuffer2.copyPixels(bBuffer2,box,new Point(0,16),null,null,true)
		//bBuffer2.copyPixels(bBuffer2,box,new Point(-1,-1),null,null,true)
		//bBuffer2.copyPixels(bBuffer2,box,new Point(8,8),null,null,true)
		
		/*
		bLine.fillRect(box,0);
		bLine.copyPixels(bBuffer2,box,new Point(0,8),null,null,true)
		bLine.copyPixels(bBuffer2,box,new Point(0,16),null,null,true)
		bLine.copyPixels(bBuffer2,box,new Point(0,24),null,null,true)
		//bLine.copyPixels(bBuffer2,box,new Point(12,12),null,null,true)
		
		bBuffer2.copyPixels(bLine,box,origin)
		*/
		
		// deal with different glow types 
		switch ("fade") {
			case "fade":
					sA = Math.round((xm-Math.min(Math.abs(xc-lPos),xm))*0xFF/xm)
					bBuffer.fillRect(box,sA << 24)
					bBuffer2.copyPixels(bDraw,hitR,pt,bBuffer,origin,true)
				break
			case "full":
					bBuffer2.copyPixels(bDraw,hitR,pt,null,null,true)
				break
			default:
		}
		
		// apply filter
		
		origin.x = -w;
		bBuffer.applyFilter(bBuffer2,box,origin,dsF)
		origin.x = 0
		bBuffer.copyPixels(bDraw,hitR,pt,bBuffer,pt,true)
		
		// use our colormap
		bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
		
		// if light box reach end
		if (lPos > lMax || lPos < lMin) {
			if (lPos > lMax ) lIncr = -Math.abs(lIncr)
			if (lPos < lMin ) lIncr = Math.abs(lIncr)
			lPos += lIncr
		} else {
			lPos += lIncr
		}
	
	}
		
}