/*
	This one will add a dynamic glow effect to your objects (both animated or static)
*/

package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class glow extends Sprite {
		// hold the effect
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// some BitmapDatas used for computing
		private var bDraw:BitmapData;
		private var bBuffer:BitmapData;
		
		
		/*
		   default conf
		   colors: default gradient
		   animated: if container doesn't change, set to false
		   autoUpdate: ... you guess it
		*/
		private var conf:Object = {
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			animated:true,
			autoUpdate:true
			
		};
		
		// blur filter
		private var bF:BlurFilter
		// drop shadow filter
		private var dsF:DropShadowFilter
		
		// stuff
		private var inited:Boolean=false;
		private var rendered:Boolean=false;
		private var box:Rectangle;
		private var origin:Point;
		
		// hold light properties
		private var lite:Object = {
			angle:0,
			angleIncr:5,
			min: 0x000000,
			max: 0xFFFFFF
		};
		
		// Constructor
		function glow(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			var t = conf.target
			
			// if no width or height was given, try to autodetect
			if (!conf.width) conf.width = t.width;
			if (!conf.height) conf.height = t.height;
			
			// same position as container
			x = t.x
			y = t.y
			
			// this will hold the effect
			bMap = new Bitmap()
			bMap.blendMode = "add";
			
						
			// create the colorMap
			lite.colorMap = {
				r:new Array(256),
				a:new Array(256)
			}
			
			// zero fill
			// init() will later call buildColorMap to create the gradient
			with(lite.colorMap) {
				for (var i=0;i<256;i++) {
					r[i]=0
					a[i]=0
				}
			}
			
			// blur filter
			bF = new BlurFilter(32,32,1);
			// drop shadow filter
			dsF = new DropShadowFilter(15,0,0xFF0000,1,16,16,4,1,true,true,false)
			
			// some stuff
			origin = new Point(0,0);
			box = new Rectangle(0,0,conf.width,conf.height);
			
						
			// if auto update is false, you need to maually call init() and update()
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
			
		*/
		public function buildColorMap(c:Array=null,fill=100) {
		
			if (!c) c=conf.colors
			// we have c.length colors
			// final gradient will have 256 values (0xFF) 
			
			// starting index, if fill = 100% start with 0
			// if fill<100, 0..idx-1 values will not be changed
			var idx=Math.floor((100-fill)*255/100);
			
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
					lite.colorMap.a[idx] = color;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
			rendered = false;
		}
		
		// init stuff
		public function init() {
		
			if (inited) {
				// cleanup
				bData.dispose();
				bDraw.dispose();
				bBuffer.dispose();
			} else {
				// add the bitmap
				addChild(bMap)
			}
			
			// create the bitmaps	
			bData = new BitmapData(conf.width, conf.height, true,0x000000);
			bMap.bitmapData = bData;
			
			bDraw = bData.clone();
			bBuffer = bData.clone();
			
			// build the gradient
			buildColorMap()
						
			// add handler for auto update, if needed
			if (!inited && conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;

		}
		
		/*
		   sets light properties:
		    
		   intensity: power from 0.1 to 10
		   blur: smoothing value from 1 to 5
		   thickness: glow thickness, from 0 to 64
		   angle: starting angle from 0 to 359
		   angleIncr: angle increment
		*/
		// light intensity from 0.1 to 10
		public function light(intensity=4,thickness=15,blur=4,angle=0,angleIncr=5) {
			var q = 1 << blur
			
			dsF.strength = intensity
			dsF.distance = thickness		
			dsF.blurX = q
			dsF.blurY = q
			bF.blurX = q*2
			bF.blurY = q*2
			
			lite.angle = angle
			lite.angleIncr = angleIncr;
			
			
			rendered = false;
		}
		
		
		/*
			set the color interval of your object used as glow source
			
			params:
			
			min,max: hex colors in RGB format
		*/ 
		public function interval(min=0,max=0xFFFFFF) {
			lite.min = min
			lite.max = max
			rendered = false;
		}
		
		
		// do the magic
		public function update(e=null) {
		
			with (lite) {
				// if target is animated or no frame rendered
				if (conf.animated || !rendered) {
					// clean up
					bDraw.fillRect(box,0)
					// draw target
					bDraw.draw(conf.target,null,null,null,box)
					// if we have a color interval defined, clear colors outside the range
					if (min>0) bDraw.threshold(bDraw,box,origin,"<",min,0,0xFFFFFF,false);
					if (max<0xFFFFFF) bDraw.threshold(bDraw,box,origin,">",max,0,0xFFFFFF,false);
				}
			
				// angle increment
				angle = angle % 360 + angleIncr;
				dsF.angle = angle;
				
				// if target is animated or rotating or no frame rendered
				if (conf.animated || angleIncr != 0 || !rendered) {
					// apply the drop shadow filter to create the glow
					bBuffer.applyFilter(bDraw,box,origin, dsF);
					
					// lock, so no change will be visible until unlock()
					bData.lock();
					// apply the blur filter to smooth
					bData.applyFilter(bBuffer,box,origin, bF);
					// use our custom gradient for glow color
					bData.paletteMap(bData,box,origin,colorMap.r,null,null,colorMap.a)
					bData.unlock();
				}
				rendered = true;
			}
		
		}
		
	}
}