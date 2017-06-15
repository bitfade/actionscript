import flash.geom.*
import flash.display.BitmapData

class bitfade.AS2.utils.crop {

	public static function hitBox(bm:BitmapData,w,h):Rectangle {
		
		if (w == undefined ) w = bm.width
		if (h == undefined ) h = bm.height
		
		var xs:Number=0
		var xe:Number=w
		var ys:Number=0
		var ye:Number=h
		
		var hb = new Rectangle(0,0,1,h)
		
		var origin = new Point();
		
		
		with (hb) { x=0;y=0;width=1;height=h }
		while (!bm.hitTest(origin,0x01,hb)) if (++hb.x > w-1) break;
		xs = hb.x
		hb.x=w-1
		while (!bm.hitTest(origin,0x01,hb)) if (--hb.x < 1) break;
		xe = hb.x
		with (hb) { x=0;y=0;height=1;width=w }
		while (!bm.hitTest(origin,0x01,hb)) if (++hb.y > h-1) break;
		ys = hb.y
		hb.y=h-1
		while (!bm.hitTest(origin,0x01,hb)) if (--hb.y < 1) break;
		ye = hb.y
		with (hb) { x=xs,y=ys,width=xe-xs+1,height=ye-ys+1}
		return hb
	}

}

	