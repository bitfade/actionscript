package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class clouds extends Sprite {
		
		// default conf
		// colors: default color gradient
		// s: wave speed
		// axes: wave axes
		// pos: wave starting position
		// autoUpdate: .... you guess it
		private var conf:Object = {
			//colors:[0x000000,0xFFFFFFFF],
			colors:[0x00000000,0x50303030,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			s:[4,6,8,10],
			planes: 1,
			axes:[true,true,true,true],
			pos: [0,0,0,0],
			dx:8,
			dy:2,
			idx:0,
			max:500,
			autoUpdate:true
		};
		
		
		// bitmaps
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bBuffer2es:Array;
		private var bBuffer:BitmapData;
		private var bBuffer2:BitmapData;
		private var bAct:BitmapData;
		private var bOther:BitmapData;
		private var bDraw:BitmapData;
		private var bFire:BitmapData;
		private var bFireC:Array;
		
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
			
			fireCT = new ColorTransform(0,0,0,1,0,0,0,-0x50);
			
			//fireCT = new ColorTransform(0,0,0,1,0,0,0,0);
			
			cF = new ConvolutionFilter(
				3,3,
				[
					1,	0,	1,
					0,	2,	0,
					1,	0,	1
				]
				,6,0,false,false,0,0
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
			
			bDraw = bData.clone();
			
			
			bBuffer = bData.clone();
			bBuffer2 = bData.clone();
			
			bFire = bData.clone();
			
			bFireC = new Array(conf.planes)
			
			for (var i=0;i<conf.planes;i++) {
				bFireC[i] = bData.clone();
				//bFireC[i].perlinNoise(32,32,5,i+1,true,true,BitmapDataChannel.ALPHA,false,null)
				bFireC[i].perlinNoise(32*(i+1),32*(i+1),5,i+1,true,true,BitmapDataChannel.ALPHA,false,null)
				//bFireC[i].perlinNoise(32,32,4-i,i+1,true,true,BitmapDataChannel.ALPHA,false,null)
				bFireC[i].colorTransform(box,fireCT)
			
			}
			
			//bFire.colorTransform(box,new ColorTransform(0,0,0,.9,0,0,0))
			/*
			bFire = new BitmapData(16*8,16*8,true,0x000000);
			
			bFire.noise(1,0,255,BitmapDataChannel.ALPHA)
			
			sbox.width = 8
			sbox.height = 8
			
			for (var xp:uint=0;xp<16;xp++)
				for (var yp:uint=0;yp<16;yp++) {
					sbox.x = xp*8
					sbox.y = yp*8
					//bFire.fillRect(sbox,((xp*16+yp) << 24) + 0xFFFFFF)
					bFire.fillRect(sbox,((xp*16+yp) << 24) + 0)
			}
			
			sbox.width = conf.dx
			sbox.height = conf.dy
			*/
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
			for (var i=0;i<conf.planes;i++) {
			
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
					//p += Math.random()*2+1
				
				}
				
				max = conf[dimension]
				
				if (p > max) p -= max 
				if (p < 0) p += max
				
				conf.pos[i] = p
 				
 				sbox[axe] = p
				sbox[dimension] = max - p
		
				bFire.copyPixels(bFireC[i], sbox, origin,null,null,i != 0)
			
				dpt[axe] = max - p
				sbox[axe] = 0
				sbox[dimension] = p
			
				bFire.copyPixels(bFireC[i], sbox, dpt,null,null, i != 0)
			}
			
			/*
			bData.copyPixels(bFire,box,origin)
			bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			return
			*/
			
			conf.max=300
			conf.idx++
			
			var fire:Shape = new Shape();
			
			if (!swap) {
			with (fire.graphics) {
				lineStyle(1,0,0);
				beginFill(0,0xFF)
				drawCircle(295,150,8)
				endFill()
			}
				swap = true
				bDraw.draw(fire,null,null,null,box)
			
			} else {
				bDraw = bBuffer2
			}
			
			if (conf.idx < conf.max) {
				var gF = new DropShadowFilter(conf.width,0,0xFF0000,1,32,32,7,1,false,false,false)
			
			
				origin.x = -conf.width;
				bBuffer.applyFilter(bDraw,box,origin, gF);
				origin.x = 0
			}
			
			bBuffer2.colorTransform(box,new ColorTransform(0,0,0,.8,0,0,0,0))
			
			//dpt.y += 0.5
			
			if (conf.idx<conf.max) bBuffer2.copyPixels(bFire,box,origin,bBuffer,origin,true)
			
			
			bData.copyPixels(bBuffer2,box,origin)
			bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			return
			
		
			var newMoon:Shape = new Shape();
            
            var xp:uint,yp:uint
            
            bDraw.fillRect(box,0)
            
            xp = 295+(Math.random()*30-15)
            yp = 150+(Math.random()*100-50)
            
            newMoon.graphics.lineStyle(1,0,0);
            newMoon.graphics.beginFill(0,0x01);
            newMoon.graphics.moveTo(295, 300); 
            newMoon.graphics.curveTo(295-Math.random()*30-20, 280, xp, yp);
            newMoon.graphics.curveTo(295+Math.random()*30+20, 280, 295, 300);    
            //newMoon.graphics.curveTo(50, 150, 100, 100);
            //newMoon.graphics.endFill();
            
            
            	
			bDraw.draw(newMoon,null,null,null,box)
            
            var gF = new DropShadowFilter(conf.width,0,0x000000,1,64,64,3,1,false,false,false)
			
			origin.x = -conf.width;
			bBuffer.applyFilter(bDraw,box,origin, gF);
			origin.x = 0
            
            
            //bData.applyFilter(bDraw,box,origin,gF)
            //bData.paletteMap(bData,box,origin,null,null,null,colorMap)
            
            dpt.y=Math.random()*4-2
            
            bData.lock();
            bData.colorTransform(box,new ColorTransform(0,0,0,.2,0,0,0,0))
            bData.copyPixels(bFire,box,dpt,bBuffer,origin,true)
            bData.paletteMap(bData,box,origin,null,null,null,colorMap)
            bData.unlock()
            return

		
		
			var r = new Rectangle(0,0,100,100)
			var alpha;
		
			bBuffer.fillRect(box,0)
			bDraw.fillRect(box,0)
			
			
			
			for (var i=0;i<10;i++) {
				r.width = 50
				r.height = 20
				r.x = 295+(Math.random()*4)-2
				r.y = 300 - i*20
				alpha = ((250-i*20)) << 24
				bBuffer.fillRect(r,alpha)
				//bDraw.copyPixels(bFire,r,origin,bBuffer,origin,true)
			}
			
			/*
			for (var i=0;i<100;i++) {
				r.width = Math.random()*50
				r.height = 	Math.random()*100+50
				r.x = Math.random()*500+50
				r.y = 300 - r.height
				alpha = (Math.random()*200+50) << 24
				bBuffer.fillRect(r,alpha)
				//bDraw.copyPixels(bFire,r,origin,bBuffer,origin,true)
			}
			*/
			
			dpt.y = Math.random()*30
			bDraw.copyPixels(bFire,box,dpt,bBuffer,origin,false)
			
			var bF = new BlurFilter(32,32,1)
			
			bBuffer.applyFilter(bDraw,box,origin,bF)
		
			bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			//bData.copyPixels(bFire,box,origin)
			return
			
			var xp:uint,yp:uint
			
			var maxW=conf.width/conf.dx
			var maxH=conf.height/conf.dy
			
			bAct = (swap) ? bBuffer : bBuffer2
			bOther = (swap) ? bBuffer2 : bBuffer
			
			swap = !swap;
			
			//if (Math.random() > 0.5)
			for(var i=0;i<64;i++) {
				xp = Math.random()*(maxW-1)+1
				yp = maxH-4
				bAct.setPixel32(xp,yp,0xFF000000)
				bAct.setPixel32(xp,yp+1,0xFF000000)
				bAct.setPixel32(xp+1,yp,0xFF000000)
				bAct.setPixel32(xp+1,yp+1,0xFF000000)
			}
			
			
			for(var i=0;i<64;i++) {
				xp = Math.random()*maxW
				yp = maxH-Math.random()*(maxH/2)
				bAct.setPixel32(xp,yp,0)
			}
		
			bOther.applyFilter(bAct,box,origin,cF)
			
			
			var n:uint
			
			
			sbox.width = sbox.height = 2
			
			//bDraw.fillRect(box,0)
			
			//bDraw.colorTransform(box,new ColorTransform(0,0,0,.95,0,0,0,0))
			
			var dx:uint = conf.dx
			var dy:uint = conf.dy
			
			var xf:uint,yf:uint
			
			
			for (xp=0;xp<maxW;xp++) {
				for (yp=0;yp<maxH;yp++) {
					n = bOther.getPixel32(xp,yp)
					xf = xp << 1
					yf = yp << 1
					bDraw.setPixel32(xf,yf,n)
					bDraw.setPixel32(xf+1,yf,n)
					bDraw.setPixel32(xf,yf+1,n)
					bDraw.setPixel32(xf+1,yf+1,n)
					/*
					n = bOther.getPixel32(xp,yp) >>> 24
					
					if (n == 0) continue
					dpt.x = xp*dx-8
					dpt.y = yp*dy-8
					
					sbox.x = (n >> 4) * 8
					sbox.y = (n & 15) * 8
					 
					
					bDraw.copyPixels(bFire,sbox,dpt,null,null,true)
					*/
					/*
					sbox.x = xp*2
					sbox.y = yp*2
					
					bDraw.fillRect(sbox,bOther.getPixel32(xp,yp))
					*/
					/*
					n = bOther.getPixel32(xp,yp)
					bDraw.setPixel32(xp*dx,yp*dy,n)
					bDraw.setPixel32(xp*dx+1,yp*dy,n)
					bDraw.setPixel32(xp*dx,yp*dy+1,n)
					bDraw.setPixel32(xp*dx+1,yp*dy+1,n)
					*/
					
				}
			}
			//bData.copyPixels(bDraw,box,origin)
			
			var bF = new BlurFilter(2,2,1)
			
			bDraw.applyFilter(bFire,box,origin,bF)
			
			bData.paletteMap(bDraw,box,origin,null,null,null,colorMap)
		
		}
		
	}
}