/*
	This one will apply a laser light effect to your objects (both animated or static).
*/

package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.utils.*
	
	public class laser extends Sprite {
		/*
		   
			default conf
		   
			colors: 				default gradient
			maskMode:				if true, draw only portions of target hit by laser
		   
			laserWidth: 			laser width
			laserSpeed:				laser speed
			laserXmin,laserXmax:	laser x interval
			laserY:					laser starting y position
			laserHeight:			laser height
			
			
			laserIntensity: 		laser intensity (laser only)
			
			glowSize:				glow size of target hit by laser
			glowIntensity:			glow intensity of target hit by laser
			persistence: 			persistence of target hit by laser
			
			blendMode:				blendMode
		   
			autoUpdate:				if true (default), auto update effect
		*/
		private var conf:Object = {
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			maskMode: true,
			
			laserSpeed:5,
			laserWidth: 20,
			laserIntensity: 0x40,
			
			
			glowSize: 16,
			glowIntensity: 1,
			persistence: 0.8,
			
			blendMode: "add",
			autoUpdate:true
		};

	
		private var bMap:Bitmap;
		private var bData:BitmapData;		
		private var bDraw:BitmapData;
		private var bBuffer:BitmapData;
		private var bBuffer2:BitmapData;
		
		private var colorMap:Array;
		
		private var fadeCT:ColorTransform;
		
		private var gF:DropShadowFilter;
		
		private var inited:Boolean=false;
		private var box:Rectangle;
		private var lbox:Rectangle;
		private var origin:Point;
		private var gFp:Point;
		
		
		// Constructor
		function laser(opts:Object){
			
			bMap = new Bitmap()
			fadeCT = new ColorTransform(0,0,0,.8,0,0,0,0);
			colorMap = new Array(256),
			
			configure(opts)
				
			// some stuff
			origin = new Point(0,0);
			gFp = new Point(-conf.width,0)
			box = new Rectangle(0,0,conf.width,conf.height);
			lbox = new Rectangle(0,0,conf.width,conf.height);
						
			// if auto update is false, you need to maually call init() and update()
			if (conf.autoUpdate) init();
			
		}
		
		public function configure(opts:Object) {
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			var t = conf.target
			
			// if no width or height was given, try to autodetect
			if (!conf.width) conf.width = t.width;
			if (!conf.height) conf.height = t.height;
			
			if (!conf.laserY || !conf.laserHeight) {
				conf.laserY = 0
				conf.laserHeight = conf.height
			}
			
			if (!conf.laserXmin || !conf.laserXmax) {
				conf.laserXmin = conf.width/2 - 150
				conf.laserXmax = conf.width/2 + 150
			}
			

			if (!conf.laserX) conf.laserX = conf.laserXmin
			
			bMap.blendMode =  conf.blendMode
			
			if (!gF) {
				gF = new DropShadowFilter(conf.width,0, 0x000000,1,conf.glowSize,conf.glowSize,conf.glowIntensity,1,false,false,false)
			} else {
				with (gF) {
					blurX = blurY = conf.glowSize
					strength = conf.glowIntensity
				}
			}
			
			if (opts.colors) buildColorMap()
			
			fadeCT.alphaMultiplier = conf.persistence
			
			// same position as container
			x = t.x
			y = t.y
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
			a color is specified in ARGB hex format:
			
			0xAARRGGBB 
			
			where
			
			AA = alpha
			RR = red
			GG = green
			BB = blue
			
		*/
		public function buildColorMap(c:Array=null) {
		
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
					colorMap[idx] = cur.a << 24 | cur.r << 16 | cur.g << 8 | cur.b;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
		}
		
		// init stuff
		public function init() {
		
			if (inited) {
				// cleanup
				bData.dispose();
				bDraw.dispose();
				bBuffer.dispose();
				bBuffer2.dispose();
			} else {
				// add the bitmap
				addChild(bMap)
			}
			
			// create the bitmaps	
			bData = new BitmapData(conf.width, conf.height, true,0x000000);
			bMap.bitmapData = bData;
			
			bDraw = bData.clone();
			bBuffer = bData.clone();
			bBuffer2 = bData.clone();
			
			// build the gradient
			buildColorMap()
			
			// add handler for auto update, if needed
			if (!inited && conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;

		}
		
		
		// do the magic
		public function update(e=null) {
		
		
			bDraw.fillRect(box,0)
			bDraw.draw(conf.target,null,null,null,box)
			
			
			bBuffer.colorTransform(box,fadeCT)
			
			with (conf) {
				if (laserX>laserXmax || laserX<laserXmin) laserSpeed = -laserSpeed
				laserX += laserSpeed
				
				lbox.x = laserX
				lbox.y = laserY
				lbox.width = laserWidth
				lbox.height = laserHeight
				
				bBuffer.fillRect(lbox,laserIntensity << 24)
				
				lbox.y = 0
				lbox.height = height
				
				origin.x = laserX
				bBuffer.copyPixels(bDraw,lbox,origin,null,null,true)
				origin.x = 0
			
			}
			
			bBuffer2.applyFilter(bBuffer,box,gFp,gF);
			
			bData.lock()				
			if (conf.maskMode) {
				bData.fillRect(box,0)
				bData.copyPixels(bDraw,box,origin,bBuffer2,origin,true)
				bBuffer2.paletteMap(bBuffer2,box,origin,null,null,null,colorMap)
				bData.draw(bBuffer2,null,null,"add",box)
			} else {
				bData.paletteMap(bBuffer2,box,origin,null,null,null,colorMap)
			}
			
			bData.unlock()
		}
		
	}
}