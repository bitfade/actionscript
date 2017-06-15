/*
	This effect will use your object (both animated or static) as source of fire.
	you can use the entire object of just a portion based on a color interval
*/

package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class burn extends Sprite {
		// hold the effect
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// some BitmapDatas used for computing
		private var bDraw:BitmapData;
		private var bBuffer:BitmapData;
		private var bBuffer2:BitmapData;
		
		// hold the noise (flames)
		private var bNoise:BitmapData;
		
		/*
		   default conf
		   channel: channel data (RED|GREEN|BLUE) used to emit fire
		   colors: default gradient
		   autoUpdate: ... you guess it
		*/
		private var conf:Object = {
			channel:BitmapDataChannel.RED,
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			autoUpdate:true
			
		};
		
		// some ColorTransforms used for alter colors
		private var copyCT:ColorTransform;
		private var fadeCT:ColorTransform;
		private var noiseCT:ColorTransform;
		
		// blur filter
		private var bF:BlurFilter
		
		// stuff
		private var inited:Boolean=false;
		private var box:Rectangle;
		private var fbox:Rectangle;
		private var origin:Point;
		
		// hold fire properties
		private var fire:Object = {
			scrollMax:250
		};
		
		// Constructor
		function burn(opts:Object){
			
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
			
			
			
			// colorTrasform used to copy the target
			copyCT = new ColorTransform(1,1,1,0,0,0,0,0x80);
			// colorTrasform used to fade out the effect
			fadeCT = new ColorTransform(.88,0,0,1,0,0,0,0);
			// colorTrasform used to reduce flames intensity
			noiseCT = new ColorTransform(.3,0,0,1,0,0,0,0);
				
			// set things for use specified channel as fire emitter
			switch (conf.channel) {				
				case BitmapDataChannel.RED:
					fire.mask = 0xFF0000
					fire.mult = 256*256;
				break
				case BitmapDataChannel.GREEN:
					fire.mask = 0xFF00
					fire.mult = 256;
					break
				case BitmapDataChannel.BLUE:
					fire.mask = 0xFF
					fire.mult = 1;
			}
			
			// create the colorMap
			fire.colorMap = {
				r:new Array(256),
				a:new Array(256)
			}
			
			// zero fill
			// init() will later call buildColorMap to create the gradient
			with(fire.colorMap) {
				for (var i=0;i<256;i++) {
					r[i]=0
					a[i]=0
				}
			}
			
			// blur filter
			bF = new BlurFilter(8,16,1);
			
			// some stuff
			origin = new Point(0,0);
			box = new Rectangle(0,0,conf.width,conf.height);
			fbox = new Rectangle(0,0,conf.width,conf.height);
			
						
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
					fire.colorMap.r[idx] = color;
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
				bNoise.dispose();
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
			
			/*
				bNoise is the key.
				
				we'll use perlinNoise to create a flame-like pattern
				then, we'll use this pattern fo fill bNoise, wich is higher then target.
				 
				we can later scroll bNoise and simulate flames moving up
			
			*/
			
			// create the bitmap
			bNoise = new BitmapData(conf.width, conf.height+fire.scrollMax,true,0x000000);
			
			// create the pattern
			var noise = new BitmapData(conf.width,fire.scrollMax,true,0x000000)
			noise.perlinNoise(16,16,2,1,true,true,BitmapDataChannel.RED | BitmapDataChannel.ALPHA,false,null)
			
			// fill bNoise with pattern
			for (var start=0;start<(conf.height+fire.scrollMax);start += fire.scrollMax) {
				origin.y = start
				bNoise.copyPixels(noise,noise.rect,origin,null,null,false)
			}
			origin.y = 0
			
			// pattern not needed anymore
			noise.dispose();
			
			// use a ColorTransform to reduce flames intensity
			bNoise.colorTransform(bNoise.rect,noiseCT)
			
			// build the gradient
			buildColorMap()
			
			// set the amount
			amount();
			
			// set the power
			power();
			
			// add handler for auto update, if needed
			if (!inited && conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;

		}
		
		/*
			set the amount of your object used as source of fire.
			you can use all (default) or just a region.
			
			for this to work, you choose a color channel, say RED, and
			define an interval, say 100 - 200.
			
			this way, only regions with RED value from 100 to 200 will emit fire
			 
			you choose color channel (RED,GREEN,BLUE) when creating the burn object
			for examples and better explanation see help.txt
			
			params:
			
			max,min: define interval from min to max.
			maxInc: if set, will be added to max at every step
			minInc: if set, will be added to max at every step
			delay: if set, and max=min, process delay frames than stop. 
		*/ 
		public function amount(max=0xFF,min=0,maxInc=0,minInc=0,delay=0) {
			fire.max = max * fire.mult;
			fire.min = min * fire.mult;
			fire.maxInc = maxInc * fire.mult; 
			fire.minInc = minInc * fire.mult;
			fire.active = true;
			if (delay > 0) {
				fire.end = true;
				fire.delay = delay;
			} else {
				fire.end = false;
			}
		}
		
		/*
		   this set fire power
		   pow: power from 0 to 100
		   powInc: if set, will be added to power at every step
		*/
		public function power(pow=85,powInc=0) {
			
			copyCT.alphaOffset = (pow>30) ? 127*pow/100 + 128 :  166*pow/30
			fadeCT.redMultiplier =  0.28*pow/100 + 0.6

			fire.pow = pow;
			
			if (pow == 0 && powInc <= 0) {
				fire.powInc = 0;
				fire.active = false;
				fire.delay=0
			} else {
				fire.powInc = powInc;
				fire.active = true;
			}
			
		}
		
		// do the magic
		public function update(e=null) {
		
			with (fire) {
				// if fire is active
				if (active) {
				
				// empty the drawing buffer
				bBuffer.fillRect(box,0)
				
				// draw target using copyCT, only conf.channel which can be RED, GREEN, or BLUE
				bBuffer.draw(conf.target,null,copyCT,"normal",box)
				
				// erase pixels with conf.channel component greater then max
				if (max != mask) bBuffer.threshold(bBuffer,box,origin,">",max,0,mask,false);
				// erase pixels with conf.channel component lesser then min
				if (min != 0) bBuffer.threshold(bBuffer,box,origin,"<",min,0,mask,false);
				
				// if we have increments, process them 
				if (maxInc != 0) {
					max = Math.max(Math.min(max + maxInc,mask),min);
					// if max reached maximum value or min, clear maxInc
					maxInc = (max == mask || max == min) ? 0 : maxInc
					// if user requested stopping fire, deactivate it
					if (max == min && end) active = false;
				} 
				if (minInc != 0) {
					min = Math.min(Math.max(min + minInc,0),max);
					// if max reached 0 or max, clear minInc
					minInc = (min == 0 || min == max) ? 0 : minInc
					// if user requested stopping fire, deactivate it
					if (max == min && end) active = false;
				}	
				if (powInc != 0) {
					pow = Math.min(Math.max(pow + powInc,0),100);
					power(pow,powInc);
				}	
				// scroll bNoise
				fbox.x = Math.random()*4-2;
				fbox.y = fbox.y % scrollMax + 5
				
				// now copy the scrolled bNoise using our processed target as mask
				bBuffer2.copyPixels(bNoise,fbox,origin,bBuffer,origin,false)
				
				} else {
					// if fire is not active, and delay == 0, we have nothing to do
					if (delay == 0) return
					// else, countdown
					delay--
				}
			
			}
			
			// scroll up the drawing area 
			bDraw.scroll(0,-5)
			// fade out
			bDraw.colorTransform(box,fadeCT)
			// if fire is active, add bBuffer2
			if (fire.active) bDraw.draw(bBuffer2,null,null,"add",box)
					
			// use our colorMap
			bBuffer.paletteMap(bDraw,box,origin,fire.colorMap.r,null,null,fire.colorMap.a)
			
			bData.lock()
			// apply the blur filter to smooth things out 
			bData.applyFilter(bBuffer,box,origin, bF);
			bData.unlock();
		}
		
	}
}