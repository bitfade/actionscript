package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class water extends Sprite {
		
		// default conf
		// colors: default color gradient
		// s: wave speed
		// axes: wave axes
		// pos: wave starting position
		// autoUpdate: .... you guess it
		private var conf:Object = {
			colors:[0xFF040E29,0xFF14385C,0xFF3D5F9C,0xFFB7DBFF],
			s:[2,-2,-1],
			axes:[false,false,true],
			pos: [0,0,0],
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
		
		
		function water(opts:Object){
			
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
			
			waveCT = new ColorTransform(0,0,0,1,0,0,0,-0x40);
			
			if (conf.autoUpdate) init();
		}
		
		// helper: convert hex color to object (used internally)
		private function hex2rgb(hex) {
			return {
				a:hex >>> 24,
				r:hex >>> 16 & 0xff,
				g:hex >>> 8 & 0xff, 
				b:hex & 0xff 
			}
		}
		
		/* 
			helper: create a gradient based on n colors
			c is an array of colors, fill is % of the map to be covered
			a color is specified in ARGB hex format:
			
			0xAARRGGBB 
			
			where
			
			AA = alpha
			RR = red
			GG = green
			BB = blue
			
			maxAlpha: max alpha value
			
		*/
		public function buildColorMap(c:Array=null,maxAlpha=0xFF) {
		
			if (!c) c=conf.colors
			// we have c.length colors
			// final gradient will have 256 values (0xFF) 
			
			var idx=0;
			
			
			// number of sub gradients = number of colors - 1
			var ng=c.length-1
			
			// each sub gradient has 256/ng values
			var step=256/ng;
			
			var cur:Object,next:Object;
			var rs:Number,gs:Number,bs:Number,al:Number,color:uint
			
			// for each sub gradient
			for (var g=0;g<ng;g++) {
				// we compute the difference between 2 colors 
			
				// current color
				cur = hex2rgb(c[g])
				// next color
				next = hex2rgb(c[g+1])
				
				// RED delta
				rs = (next.r-cur.r)/(step)
				// GREEN delta
				gs = (next.g-cur.g)/(step)
				// BLUE delta
				bs = (next.b-cur.b)/(step)
				// ALPHA delta
				al = (next.a-cur.a)/(step)
				
				// compute each value of the sub gradient
				for (var i=0;i<=step;i++) {
					color = Math.min(cur.a,maxAlpha) << 24 | cur.r << 16 | cur.g << 8 | cur.b;
					colorMap[idx] = color;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
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
			bData = new BitmapData(conf.width,conf.height,true,0x000000);
			bMap.bitmapData = bData;
			
			bBuffer = bData.clone();
			
			for (var i=0;i<3;i++) bWaves[i] = bData.clone();
			
			for (i=0;i<3;i++) {
				bWaves[i].perlinNoise(128,16,i != 2 ? 4 : 1,i+1,true,true,BitmapDataChannel.ALPHA,false)
				bWaves[i].colorTransform(box,waveCT)
			}
			
			buildColorMap();
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
		}
		
		public function update(e=null) {
		
			var p,axe,dimension,max:uint
			
			
			// scroll waves
			for (var i=0;i<3;i++) {
			
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
 				
 				sbox[axe] = p
				sbox[dimension] = max - p
		
				bBuffer.copyPixels(bWaves[i], sbox, origin,null,null,i != 0)
			
				dpt[axe] = max - p
				sbox[axe] = 0
				sbox[dimension] = p
			
				bBuffer.copyPixels(bWaves[i], sbox, dpt,null,null, i != 0)
			}
						
			// use our gradient
			bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			bBuffer.colorTransform(box,new ColorTransform(0,0,0,1,0,0,0,0))
			//if (conf.onUpdate) conf.onUpdate(bBuffer)
		}
		
	}
}