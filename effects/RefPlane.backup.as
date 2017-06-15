package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	
	public class refPlane extends Sprite {
		// hold the reflection
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// alpha channel
		private var alphaC:BitmapData;
		
		// buffer
		private var bDraw:BitmapData;
		
		// default conf
		// falloff: reflection lenght
		// alpha: reflection max alpha value
		// autoUpdate: ... you guess it
		// w,h: used internally
		private var conf:Object = {falloff:80,alpha:100,autoUpdate:true,w:0,h:0};
		
		// stuff
		private var refM:Matrix;
		private var origin:Point;
		private var box:Rectangle;
		private var inited:Boolean=false;
		
		
		function refPlane(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			var t = conf.target
			
			// if no width or height was given, try to autodetect
			if (!conf.width) conf.width = t.parent.width;
			if (!conf.height) conf.height = t.parent.height - conf.falloff;
			
			// same position as container
			x = t.x
			y = t.y
			
			// this will hold reflection
			bMap = new Bitmap()
			// flip upside down
			bMap.scaleY = -1;
			
			// see init()
			refM = new Matrix()
			origin = new Point(0,0);
			box = new Rectangle(0,0,conf.w,1);
			
			mouseEnabled = false
			
			if (conf.autoUpdate) init();
		}
		
		public function init() {
		
			var t = conf.target
			var sr = t.scrollRect
			// if target has no scrollRect, build it
			if (!sr) {
				sr = new Rectangle(0,0,conf.width,conf.height)
				t.scrollRect = sr;				
			} 
			
			var w = sr.width
			var h = sr.height
			
			// if you change width/height, e.g. on window resize or fullscreen, init() has to be
			// called again to rebuild stuff. 
			// however, if you call init but width and height are unchanged, nothing has to be done
			if (conf.h == h && conf.w == w ) return
			
			conf.w = w
			conf.h = h
			
			box.width = conf.w
			
			if (inited) {
				alphaC.dispose();
				bData.dispose();
				bDraw.dispose();
			} else {
				addChild(bMap)
			}
			
			// create empty bitmapDatas
			alphaC = new BitmapData(w, conf.falloff, true,0x000000);
			bData = alphaC.clone();
			bDraw = alphaC.clone();
			
			// build the alpha channel
			// in short, this is just an horizontal gradient of alpha values from 0 to conf.alpha
			for (var i=0,alpha=0,delta=(conf.alpha/conf.falloff); i<=conf.falloff; i++,alpha=(delta*i<<24)) {
				box.y = i
				alphaC.fillRect(box,alpha)
			}
			
			// box is the region that will be reflected 
			// 0,0,conf.witdh,conf.falloff 
			box.y=0;
			box.height = conf.falloff;
			
			bMap.bitmapData = bData;
			bMap.y = h+conf.falloff
			
			// this matrix will be used to shift (y axis) the target, 
			// so we can only redraw the region needed for reflection
			refM.ty = conf.falloff-h
			
			if (!inited && conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
			update()
		}
		
		public function update(e=null) {
			// clear
			bData.fillRect(box,0)
			bDraw.fillRect(box,0)
				
			// here starts the magic:
			// redraw target on our temp bitmapData buffer, only the region needed for reflection
			bDraw.draw(conf.target,refM,null,null,box);
			// now copy the buffer on the real bitmap, but use alphaC for the alpha channel 
			// again: we will copy *only* what needed
			bData.copyPixels(bDraw, box, origin, alphaC, origin, true);
				
		}
		
	}
}