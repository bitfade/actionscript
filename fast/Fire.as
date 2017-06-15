package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class fire extends Sprite {
		
		/*
		 
		 default conf
		 
		 fireColors: default fire color gradient
		 fireAmount: amount of fire
		 fireMaxSpeed: max speed of fire
		 
		 smokeColors: default smoke color gradient
		 smokeAmount: amount of smoke
		 smokeMaxSpeed: max speed of smoke
		 
		*/
		private var conf:Object = {
			fireColors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			fireAmount: 40,
			fireMaxSpeed: 3,
			
			smokeColors:[0x00FFFFFF,0xFF000000],
			smokeAmount: 30,
			smokeMaxSpeed: 4,
			
			autoUpdate:true,
			flameSize:128,
			flameFrames:64
		};
		
		
		// bitmaps
		private var bMap:Bitmap
		public var bData:BitmapData
		private var bBuffer:BitmapData;
		private var bFirePart:Array;
		
		// stuff
		private var origin:Point
		private var dpt:Point;
		private var box:Rectangle
		private var inited:Boolean=false;
		private var colorMapFire:Array;
		private var colorMapSmoke:Array;
		
		
		// constructor
		function fire(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			// this will contain clouds
			bMap = new Bitmap()
			bMap.blendMode="normal"
			
			origin = new Point(0,0);
			dpt = new Point(0,0)
			box = new Rectangle(0,0,conf.width,conf.height);
			
			colorMapFire = new Array(256)
			colorMapSmoke = new Array(256)
			
			if (conf.autoUpdate) init();
		}
		
		// init stuff
		public function init() {
			
			if (!inited) addChild(bMap)
			
			// create empty bitmapDatas
			bData = new BitmapData(conf.width,conf.height,true,0x000000);
			bMap.bitmapData = bData;
			
			bBuffer = bData.clone();
			
			buildColorMap()
			preRenderFlames()
			area()
			start()
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
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
			fireC,smokeC are arrays of colors, 
			each color is specified in ARGB hex format:
			
			0xAARRGGBB 
			
			where
			
			AA = alpha
			RR = red
			GG = green
			BB = blue
			
			maxAlpha: max alpha value
			
		*/
		public function buildColorMap(fireC:Array=null,smokeC:Array=null) {
			_buildColorMap(colorMapFire,fireC ? fireC : conf.fireColors)
			_buildColorMap(colorMapSmoke,smokeC ? smokeC : conf.smokeColors)			
		}
		
		private function _buildColorMap(colorMap:Array,c:Array=null) {
		
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
					color = cur.a << 24 | cur.r << 16 | cur.g << 8 | cur.b;
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
		
			set fire/smoke amount
			
			fireQ: from 0 (disable fire) to 200
			smokeQ: from 0 (disable smoke) to 200
		
		*/
		public function amount(fireQ=40,smokeQ=30) {
			with(conf) {
				fireAmount = fireQ
				smokeAmount = smokeQ
			}
		}
		
		/*
		
			set fire/smoke max speed
			
			fireS: from 1 to 10
			smokeS: from 1 to 10
		
		*/
		public function speed(fireS=3,smokeS=4) {
			with(conf) {
				fireMaxSpeed = fireS
				smokeMaxSpeed = smokeS
			}
		}
		
		/*
		
			set fire/smoke area
			
			xmin-xmax: 	x interval
			ymin:		y starting position
			
		*/
		public function area(xmin=null,xmax=null,ymin=null) {
			conf.xmin = (xmin !== null) ? xmin : (conf.width >> 1)-200
			conf.xmax = (xmax !== null) ? xmax : (conf.width >> 1)+200
			conf.ymin = (ymin !== null) ? ymin : conf.height + (conf.flameSize >> 1)
		}
		
		// flames renderer
		private function preRenderFlames() {
			
			var flameSize:uint=conf.flameSize
			var flameSizeHalf:uint = flameSize >> 1
			
			var bFire = new BitmapData(flameSize << 1,3*conf.flameFrames+flameSize,true,0x000000);
			bFire.perlinNoise(32,32,5,1,true,true,BitmapDataChannel.ALPHA,false,null)
			
			bFirePart = new Array(conf.flameFrames)
			
			var flame:Shape = new Shape();
			var bFlame = new BitmapData(flameSize,flameSize,true,0x000000);
			
			var gradM = new Matrix();
			gradM.createGradientBox(flameSize,flameSize,0, 0, 0);
			
			with (flame.graphics) {
				lineStyle(1,0,0);
				beginGradientFill(
					GradientType.RADIAL, 
					[0x000000,0x000000,0x000000], 
					[1,1,0], 
					[0,80,255], 
					gradM, 
					SpreadMethod.PAD
				);
				drawCircle(flameSizeHalf,flameSizeHalf,flameSizeHalf)
				endFill()
			}
			
			
			var r=new Rectangle(0,0,flameSize,flameSize)
			
			bFlame.draw(flame,null,null,null,r)
			
			
			var cF = new ConvolutionFilter(3,3,null,3.1,0,false,false,0,0) 
			
			
			var cfM = [
				[0,1,0,0,1,0,0,1,0],
				[0,0,1,0,1,0,1,0,0],
				[0,0,0,1,1,1,0,0,0],
				[0,0,1,0,1,0,1,0,0]
			]
			
			for (var i=0;i<conf.flameFrames;i++) {
				r.y += 3
				bFirePart[i] = new BitmapData(flameSize,flameSize,true,0x000000);
				bFirePart[i].copyPixels(bFire,r,origin,bFlame,origin,false)
				
				cF.matrix = cfM[Math.round(Math.random()*3)]
				bFlame.applyFilter(bFlame,bFlame.rect,origin,cF)		
			}
		
		}
		
		
		// add fire
		private function start(j=-1) {
		
			var pdy:uint,px:int;
			var h:uint = conf.ymin
			var amount:uint
			var fireAmount:uint = conf.fireAmount
			var xmin:uint = conf.xmin << 5
			var xdelta:uint = (conf.xmax - conf.xmin) << 5
			var all:Boolean=false
			var fireMaxSpeed = conf.fireMaxSpeed
			var smokeMaxSpeed = conf.smokeMaxSpeed
			
			var i:uint
			
			if (j<0) {
				amount = fireAmount + conf.smokeAmount
				conf.particles = new Array(amount)
				i = 0
				all = true
			} else {
				amount = j+1
				i = j
			}
			
			for (;i<amount;i++) {
			
				pdy = Math.round(Math.random()*32*(i<fireAmount ? fireMaxSpeed : smokeMaxSpeed))+64
				px = xmin + Math.round((Math.random()*xdelta))
				
				conf.particles[i] = {
					x  : px,
					y  : ((all) ? (Math.random()*h+h) :  h) << 5,
					i  : (all) ? (Math.random()*64) << 5 : (Math.random()*4) << 5,
					dx : Math.round(Math.random()*64-32),
					dy : pdy,
					di : (i<fireAmount) ? (pdy >> 3)+4 : (pdy >> 4)+4
				}
			}		
		}
		
		public function update(e=null) {
		
			var p:Object
			var fp:BitmapData;
			
			var fireAmount:uint = conf.fireAmount
			var smokeAmount:uint = conf.smokeAmount
			var amount:uint = fireAmount + conf.smokeAmount
			var flameFrames:uint = conf.flameFrames << 5
			var j:uint,pi:uint,px:int,py:int,pdx:int,pdy:uint,pdi:uint
			var h4:uint = conf.height << 4
			var addP:Boolean = false
			
			bData.lock();
			bData.fillRect(box,0)
			if (smokeAmount > 0 ) bBuffer.fillRect(box,0)
			
			// process fire elements
			for (j=0;j<amount;j++) {
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
				
				
				
				if (addP || pi >= flameFrames || py < -(128 << 5)) {
					start(j)
					continue
				}
				
				fp = bFirePart[pi >> 5]
				
				dpt.x = (px >> 5)-64
				dpt.y = (py >> 5)-64
				
				if (j<fireAmount) {
					if (py < h4 ) pdi += 2
					bData.copyPixels(fp,fp.rect,dpt,null,null,true)
				} else {
					(fireAmount > 0 ? bBuffer : bData).copyPixels(fp,fp.rect,dpt,null,null,true)
				}
				
				py -= pdy
				pi += pdi
				if (Math.random()>0.5) pdi += 1
				px += pdx
				
				
				with(conf.particles[j]) {
					x = px
					y = py
					i = pi
					di = pdi
					dx = pdx
				}
			}
			
			bData.paletteMap(bData,box,origin,null,null,null,(fireAmount > 0 ? colorMapFire : colorMapSmoke ))
			
			if (smokeAmount > 0 && fireAmount > 0) {
				bBuffer.paletteMap(bBuffer,box,origin,null,null,null,colorMapSmoke)
				bData.copyPixels(bBuffer,box,origin,null,null,true)
			}
			
			bData.unlock();
				
		}
		
	}
}