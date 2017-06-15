package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class water extends Sprite {
		// hold the reflection
		private var bMap:Bitmap;
		private var bData:BitmapData;
		private var bWaves:BitmapData;
		private var bWaves2:BitmapData;
		private var bBack:BitmapData;
		private var bBuffer:BitmapData;
		private var bWater:BitmapData;
		
		
		// alpha channel
		private var alphaC:BitmapData;
		
		// buffer
		private var bDraw:BitmapData;
		
		// default conf
		// falloff: reflection lenght
		// alpha: reflection max alpha value
		// autoUpdate: ... you guess it
		// w,h: used internally
		private var conf:Object = {falloff:80,alpha:50,autoUpdate:true,w:0,h:0};
		
		private var dM:DisplacementMapFilter
		
		// stuff
		private var refM:Matrix;
		private var origin:Point,pt:Point;
		private var box:Rectangle;
		private var inited:Boolean=false;
		
		
		function water(opts:Object){
			
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
			pt = new Point(0,0);
			box = new Rectangle(0,0,conf.w,1);
			
			dM =  new DisplacementMapFilter(bWaves,pt,BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA,32,32, "clamp");
		
			
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
				bWaves.dispose();
			} else {
				addChild(bMap)
			}
			
			// create empty bitmapDatas
			alphaC = new BitmapData(w, conf.falloff, true,0x000000);
			bData = alphaC.clone();
			bDraw = alphaC.clone();
			bWaves = alphaC.clone();
			bWaves2 = alphaC.clone();
			bBack = alphaC.clone();
			bBuffer = alphaC.clone();
			bWater = alphaC.clone();
			
			
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
			
			// 128,8
			bBack.fillRect(box,0xFFA0A0A0)
			
			bWaves.perlinNoise(64,8,1,2,true,true,BitmapDataChannel.ALPHA ,false)
			//bWaves.noise(1,0,255,BitmapDataChannel.RED) 
			bWaves.colorTransform(box, new ColorTransform(0,0,0,.5,0,0,0,0)) 			
			
			bWaves2.perlinNoise(64,8,1,1,true,true,BitmapDataChannel.ALPHA ,false)
			//bWaves.noise(1,0,255,BitmapDataChannel.RED) 
			bWaves2.colorTransform(box, new ColorTransform(0,0,0,.5,0,0,0,0))
			
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
		
			//bData.copyPixels(bWaves, box, origin, null,null, true);	
			//bData.copyPixels(bBack, box, origin, bWaves,origin, false);	
			//return
		
			bData.fillRect(box,0x00000000)
			bDraw.fillRect(box,0x00000000)
			
			bDraw.draw(conf.target,refM,null,null,box);
			
			var speed=2
		
		
			bBuffer.copyPixels(bWaves,new Rectangle(conf.width-speed,0,speed,conf.height),origin,null,null,false)
			bWaves.scroll(speed,0)
			bWaves.copyPixels(bBuffer,new Rectangle(0,0,speed,conf.height),origin)
			
			bBuffer.copyPixels(bWaves2,new Rectangle(0,0,speed,conf.height),origin,null,null,false)
			bWaves2.scroll(-speed,0)
			bWaves2.copyPixels(bBuffer,new Rectangle(0,0,speed,conf.height),new Point(conf.width-speed,0))
		
			
			bWater.copyPixels(bBack, box, origin, bWaves,origin, false);
			bWater.copyPixels(bBack, box, origin, bWaves2,origin, true);
			
			//bWater.copyPixels(bWaves, box, origin,null,null,false);
			//bWater.copyPixels(bWaves2, box, origin,null,null,true);
			
			dM.mapBitmap = bWater
			dM.mapPoint = pt;
			
			bBuffer.copyPixels(bWater,box,origin);
			bBuffer.copyPixels(bDraw, box, origin, alphaC, origin, true);
			
			
			bData.applyFilter(bBuffer,box,origin,dM)	
			//bData.copyPixels(bBuffer,box,origin);
			
			//bData.copyPixels(bBack, box, origin, bWater,origin, true);
			return
		
		
			//bData.copyPixels(bDraw, box, origin, alphaC, origin, true);
			bData.copyPixels(bDraw, box, origin, null,null, true);
			
			
			dM.mapBitmap = bWaves
			dM.mapPoint = pt;
			
			
			
			bData.copyPixels(bBack, box, origin, bWaves,origin, true);
			
			bData.applyFilter(bData,box,origin,dM)	
			//bData.copyPixels(bBack, box, origin, bWaves,origin, true);
			return
			
			// clear
			bData.fillRect(box,0x00000000)
			bDraw.fillRect(box,0x00000000)
			
			// here starts the magic:
			// redraw target on our temp bitmapData buffer, only the region needed for reflection
			bDraw.draw(conf.target,refM,null,null,box);
			// now copy the buffer on the real bitmap, but use alphaC for the alpha channel 
			// again: we will copy *only* what needed
			bData.copyPixels(bDraw, box, origin, alphaC, origin, true);			
		}
		
	}
}