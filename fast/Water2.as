package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import bitfade.utils.*
	
	public class water2 extends Sprite {
		
		// default conf
		// colors: default color gradient
		// s: wave speed
		// axes: wave axes
		// pos: wave starting position
		// autoUpdate: .... you guess it
		private var conf:Object = {
			colors:[0xFF040E29,0xFF14385C,0xFF3D5F9C,0xFFB7DBFF],
			s:[4,-4],
			axes:[false,false],
			pos: [0,0],
			autoUpdate:true
		};
		
		
		// bitmaps
		private var bMap:Bitmap
		public var bData:BitmapData
		private var bWaves:Array;
		public var bBuffer:BitmapData;
		
		// stuff
		private var origin:Point
		private var dpt:Point;
		private var box:Rectangle
		private var sbox:Rectangle;
		private var inited:Boolean=false;
		private var colorMap:Array;
		private var waveCT:ColorTransform;
		
		
		function water2(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			// this will contain water
			bMap = new Bitmap()
			
			origin = new Point(0,0);
			dpt = new Point(0,0)
			box = new Rectangle(0,0,conf.width,conf.height);
			sbox = new Rectangle(0,0,conf.width,conf.height);
			
			colorMap = new Array(256)
			bWaves=new Array(3);
			
			waveCT = new ColorTransform(0,0,0,1,0,0,0,0);
			
			if (conf.autoUpdate) init();
		}
		
		
		
		/* 
			water movement
			
			x: integer value from -3 to 3
			
			0  = no x movement
			+n = move right
			-n = move left
			
		*/
		public function speed(x=0) {
			with(conf) {
				s[0] = x == 0 ? 2 : -x*2
				s[1] = x == 0 ? -2 : -x
			}
		}
		
		// init stuff
		public function init() {
			
			if (!inited) addChild(bMap)
			
			// create empty bitmapDatas
			bData = new BitmapData(conf.width,conf.height,true,0);
			bMap.bitmapData = bData;
			
			bBuffer = bData.clone();
			
			for (var i=0;i<2;i++) bWaves[i] = bData.clone();
			
			colorMap = colors.buildColorMap([0xFF000000,0x80000080,0xFF000000FF])
			
			
			for (i=0;i<2;i++) {
				bWaves[i].perlinNoise(512,32,3,i+1,true,true,BitmapDataChannel.ALPHA,false)
				//bWaves[i].paletteMap(bWaves[i],box,origin,null,null,null,colorMap)
				//bWaves[i].colorTransform(box,waveCT)
				
			}
			
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
		}
		
		public function update(e=null) {
		
			var p,axe,dimension,max:uint
			
			bData.lock()
			bData.fillRect(box,0)
			//bBuffer.colorTransform(box,new ColorTransform(1,1,1,0,0,0,0,0))
			//bData.colorTransform(box,new ColorTransform(1,1,1,0.9,0,0,0,0))
			
			// scroll waves
			for (var i=0;i<2;i++) {
			
				with (conf) {
					if (axes[i]) {
						axe = "y"
						dimension = "height"
						sbox.width = width
						dpt.x = 0
					} else {
						axe = "x"
						dimension = "width"
						sbox.height = height
						dpt.y = 0
					}
				
					p = pos[i];
					p += s[i]
				
				}
				
				max = conf[dimension]
				
				if (p > max) p -= max 
				if (p < 0) p += max
				
				conf.pos[i] = p
 				
 				p = uint(p+0.5)
 				
 				sbox[axe] = p
				sbox[dimension] = max - p
		
				bData.copyPixels(bWaves[i], sbox, origin,null,null,true)
			
				dpt[axe] = max - p
				sbox[axe] = 0
				sbox[dimension] = p
			
				bData.copyPixels(bWaves[i], sbox, dpt,null,null, true)
			}
			
			//bBuffer.fillRect(box,0xFF000000)
			bData.copyPixels(conf.background,box,origin,bData,origin,false)
			
			//bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			bData.unlock()
			// use our gradient
			//bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			//bBuffer.colorTransform(box,new ColorTransform(0,0,0,1,0,0,0,0))
			//if (conf.onUpdate) conf.onUpdate(bBuffer)
		}
		
	}
}