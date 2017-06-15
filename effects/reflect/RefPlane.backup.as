package gl.effects.reflect{ 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*;
	
	public class refPlane extends Sprite {
		private var bMap:Bitmap;
		private var bData:BitmapData;
		private var conf:Object = {w:0,h:0,falloff:80};
		
		private var refM:Matrix;
		private var alphaC:BitmapData;
		private var origin:Point;
		private var box:Rectangle;
		private var inited:Boolean=false;
		
		
		function refPlane(opts:Object){
			
			for (var p in opts) {
				conf[p] = opts[p];
			}
			
			refM = new Matrix()
			origin = new Point(0,0);
			box = new Rectangle(0,0,conf.w,1);
			
			bMap = new Bitmap()
			bMap.scaleY = -1;
			addChild(bMap)
			init()
			
		}
		
		public function init() {
			var sr = conf.target.scrollRect
			if (!sr) return
			
			var w = sr.width
			var h = sr.height
			
			if (conf.h == h && conf.w == w ) return
			
			conf.w = w
			conf.h = h
			
			box.width = conf.w
			
			if (inited) {
				alphaC.dispose();
				bData.dispose();
			} else {
				addChild(bMap)
			}
			
			alphaC = new BitmapData(w, conf.falloff, true,0x000000);
			bData = new BitmapData(w, conf.falloff, true,0x000000);			
			
			for (var i=0,alpha=0,delta=(200/conf.falloff)<<24; i<=conf.falloff; i++,alpha+=delta) {
				box.y = i
				alphaC.fillRect(box,alpha)
			}
			
			box.y=0;
			box.height = conf.falloff;
			
			bMap.bitmapData = bData;
			
			bMap.y = h+conf.falloff
			refM.ty = conf.falloff-h 
			if (!inited) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			update()

			inited = true;

		}
		
		public function update(e=null) {
			if (!inited) init()
			bData.fillRect(box,0x00000000)
			bData.draw(conf.target,refM,null,null,box);
			//bData.merge(alphaC,box,origin,1,1,1,256);
			//bData.copyPixels(alphaC, box, origin, alphaC, origin, true);
			bData.copyChannel(alphaC,box,origin,BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA)
		}
		
	}
}