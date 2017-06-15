package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import org.osflash.thunderbolt.Logger;
	
	public class clouds extends Sprite {
		
		// default conf
		// colors: default color gradient
		// s: wave speed
		// axes: wave axes
		// pos: wave starting position
		// autoUpdate: .... you guess it
		private var conf:Object = {
			//colors:[0x000000,0x20FFFFFF,0xFF202020],
			//colors:[0x000000,0x40808080,0x80808080,0xA0808080],
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			dx:8,
			dy:2,
			idx:0,
			fireFrames:64,
			max: 50,
			autoUpdate:true
		};
		
		
		// bitmaps
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bBuffer:BitmapData;
		private var bFire:BitmapData;
		private var bFire2:BitmapData;
		private var bFirePart:Array;
		
		// stuff
		private var swap=false
		private var origin:Point
		private var dpt:Point;
		private var box:Rectangle
		private var sbox:Rectangle;
		private var inited:Boolean=false;
		private var colorMap:Array;
		private var fireCT:ColorTransform;
		
		private var cF:ConvolutionFilter
		
		
		
		function clouds(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			// this will contain clouds
			bMap = new Bitmap()
			
			origin = new Point(0,0);
			dpt = new Point(0,0)
			box = new Rectangle(0,0,conf.width,conf.height);
			sbox = new Rectangle(0,0,conf.dx,conf.dy);
			
			colorMap = new Array(256)
			
			//fireCT = new ColorTransform(0,0,0,1,0,0,0,-0x20);
			
			fireCT = new ColorTransform(.5,0,0,1,-0x20,0,0,0);
			
			/*
			cF = new ConvolutionFilter(
				3,3,
				[
					0,	1,	0,
					1,	1,	1,
					0,	1,	0
				]
				,5.1,0,false,false,0,0
			) 
			*/
			cF = new ConvolutionFilter(
				5,5,
				[
					0,	0,	1,	0,	0,
					0,	1,	1,	1,	0,
					1,	1,	1,	1,	1,
					0,	1,	1,	1,	0,
					0,	0,	1,	0,	0
				]
				,13.28,0,false,false,0,0
			) 
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
			clouds movement
			
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
			
			
			buildColorMap();
			
			
			var partW=128,partH=128
			
			bFire = new BitmapData(partW << 1,3*conf.fireFrames+partH,true,0x000000);
			bFire.perlinNoise(32,32,5,1,true,true,BitmapDataChannel.ALPHA,false,null)
			
			
			bFirePart = new Array(conf.fireFrames)
			
			var bShape = new BitmapData(partW,partH,true,0x000000);
			var bTmp = bShape.clone();
			
			var fire:Shape = new Shape();
			
			with (fire.graphics) {
				lineStyle(1,0,0);
				beginFill(0,0xFF)
				drawCircle(partW/2,partH/2,16)
				endFill()
			}
			
			var r=new Rectangle(0,0,partW,partH)
			var p=new Point(0,0)
			
			bTmp.draw(fire,null,null,null,r)
			
			//var gF = new DropShadowFilter(partW,0,0x000000,1,64,64,16,3,false,false,false)
			//bShape.applyFilter(bTmp,r,new Point(-partW,0), gF);
			var gF = new GlowFilter(0,1,32,32,2,3,false)
			
			bShape.applyFilter(bTmp,r,origin, gF);
			
			var hb = new Rectangle(0,0,1,partH)
			var xs:uint=0,xe:uint=partW,ys:uint=0,ye:uint=partW
			
			//r.y = 5*64
			
			for (var i=0;i<conf.fireFrames;i++) {
				r.y += 3
				bFirePart[i] = new BitmapData(xe-xs+1,ye-ys+1,true,0x000000);
				bFirePart[i].copyPixels(bFire,r,origin,bShape,p,false)
				//bShape.applyFilter(bShape,bShape.rect,origin,cF)
				
				//edge detection code
				with (hb) { x=0;y=0;width=1;height=partH }
				while (!bShape.hitTest(origin,0x01,hb)) if (++hb.x >= partW/2) break;
				xs = hb.x
				hb.x=partW-1
				while (!bShape.hitTest(origin,0x01,hb)) if (--hb.x <= partW/2) break;
				xe = hb.x
				with (hb) { x=0;y=0;height=1;width=partW }
				while (!bShape.hitTest(origin,0x01,hb)) if (++hb.y >= partH/2) break;
				ys = hb.y
				hb.y=partH-1
				while (!bShape.hitTest(origin,0x01,hb)) if (--hb.y <= partH/2) break;
				ye = hb.y
				with (r) { width=xe-xs,height=ye-ys}
				with (p) { x=xs,y=ys}
				//Logger.info("info",(xe-xs+1)+" - "+(ye-ys+1))
				
			}
			
			
			conf.particles = new Array(conf.max)
			start()
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
		}
		
		
		private function start(j=-1) {
		
			var pdy:uint,px:int;
			var h:uint = conf.height+64
			var max:uint
			var all:Boolean=false
			
			var i:uint
			
			if (j<0) {
				max = conf.max	
				i = 0
				all = true
			} else {
				max = j+1
				i = j
			}
			
			for (;i<max;i++) {
			
				//pdy = Math.floor(Math.random()*32*4)+64
				pdy = Math.floor(Math.random()*32*8)+64
				px = (295 << 5) + ((Math.random()*400-200) << 5)
		
				conf.particles[i] = {
					x  : px,
					y  : ((all) ? (Math.random()*h+h) : h) << 5,
					i  : (all) ? (Math.random()*64) << 5 : 0,
					dx : Math.floor(Math.random()*64-32),
					dy : pdy,
					//di : (pdy >> 3)+4
					di : (pdy >> 4)
				}
			}		
		}
		
		public function update(e=null) {
		
			/*
			bData.fillRect(box,0)
			bData.copyPixels(bFirePart[conf.idx >> 0],bFirePart[conf.idx >> 0].rect,origin,null,null,false)
			
			conf.idx = (conf.idx + 1) % (conf.fireFrames << 0) 
			
			bData.paletteMap(bData,box,origin,colorMap2,null,null,colorMap)
			return
			*/
			
			bData.lock();
			bData.fillRect(box,0)
			
			var p:Object
			var fp:BitmapData;
			
			
			
			var max:uint = conf.max
			var fireFrames:uint = conf.fireFrames << 5
			var j:uint,pi:uint,px:int,py:int,pdx:int,pdy:uint,pdi:uint
			var addP:Boolean = false
			
			for (j=0;j<max;j++) {
				p = conf.particles[j]
				
				if (p) {
					with (p) {
						px=x
						py=y
						pi=i
						pdx=dx
						pdy=dy
						pdi=di
					}
				} else {
					addP = true
				}
				
				
				
				if (addP || pi >= fireFrames || py < -(128 << 5)) {
					start(j)
					continue
				}
				
				fp = bFirePart[pi >> 5]
				
				dpt.x = (px >> 5)-64
				dpt.y = (py >> 5)-64
				
				bData.copyPixels(fp,fp.rect,dpt,null,null,true)
				
				py -= pdy
				pi += pdi
				//if (py < (conf.height << 4) ) pdi += 2
				pdi += 1
				px += pdx
				
				
				with(conf.particles[j]) {
					x = px
					y = py
					i = pi
					di = pdi
					dx = pdx
				}
			}
			
			bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			
			bData.unlock();
				
		}
		
	}
}