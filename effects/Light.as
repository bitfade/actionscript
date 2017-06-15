/*
	This effect will use your object (both animated or static) as source of lite.
	you can use the entire object of just a portion based on a color interval
*/

package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.utils.*
	import org.osflash.thunderbolt.Logger;
	
	public class light extends Sprite {
		// hold the effect
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// some BitmapDatas used for computing
		private var bDraw:BitmapData;
		private var bBuffer:BitmapData;
		private var bBuffer2:BitmapData;
		private var shap:Shape;
		
		// hold the noise (flames)
		private var bNoise:BitmapData;
		
		/*
		   default conf
		   channel: channel data (RED|GREEN|BLUE) used to emit lite
		   colors: default gradient
		   autoUpdate: ... you guess it
		*/
		private var conf:Object = {
			channel:BitmapDataChannel.RED,
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			//colors:[0x00000000,0x80FFFFFF],
			autoUpdate:true,
			beams:50
			
		};
		
		// some ColorTransforms used for alter colors
		private var copyCT:ColorTransform;
		private var fadeCT:ColorTransform;
		private var noiseCT:ColorTransform;
		
		// blur filter
		private var bF:BlurFilter
		private var gF;
		
		// stuff
		private var inited:Boolean=false;
		private var box:Rectangle;
		private var center:Rectangle;
		private var origin:Point;
		
		
		// hold lite properties
		private var lite:Object = {
			center: {},
			width: 200,
			height: 200,
			angle:0
		};
		
		// Constructor
		function light(opts:Object){
			
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
			bMap.blendMode = "normal";
			
			
			// colorTrasform used to copy the target
			copyCT = new ColorTransform(1,0,0,1,0,0,0,0);
			// colorTrasform used to fade out the effect
			fadeCT = new ColorTransform(.5,0,0,.5,0,0,0,0);
			// colorTrasform used to reduce flames intensity
			noiseCT = new ColorTransform(.3,0,0,1,0,0,0,0);
				
			// set things for use specified channel as lite emitter
			switch (conf.channel) {				
				case BitmapDataChannel.RED:
					lite.mask = 0xFF0000
					lite.mult = 256*256;
				break
				case BitmapDataChannel.GREEN:
					lite.mask = 0xFF00
					lite.mult = 256;
					break
				case BitmapDataChannel.BLUE:
					lite.mask = 0xFF
					lite.mult = 1;
			}
			
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
			bF = new BlurFilter(64,32,1);
			gF = new GlowFilter(0xFF0000,1,128,32,1.5,1,false,true)
			
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
					lite.colorMap.r[idx] = color;
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
			
			shap = new Shape();
			
			
			// create the bitmaps	
			bData = new BitmapData(conf.width, conf.height, true,0x000000);
			bMap.bitmapData = bData;
			
			bDraw = bData.clone();
			bBuffer = bData.clone();
			bBuffer2 = bData.clone();
			
			lite.beams = new Array(conf.beams);
			
			lite.center = {
				x: conf.width/2,
				y: conf.height/2
			}
			
			lite.xmin = lite.center.x - lite.width/2;
			lite.xmax = lite.center.x + lite.width/2;
			lite.ymin = lite.center.y - lite.height/2;
			lite.ymax = lite.center.y + lite.height/2;
			
			with (lite) {
				for (var i=0;i<conf.beams;i++) {
					lite.beams[i] = {
						x: lite.center.x+Math.random()*width-width/2,
						y: lite.center.y+Math.random()*height-height/2,
						dx: Math.ceil(Math.random()*2+1)*(Math.random() > 0.5 ? -1 : 1),
						dy: Math.ceil(Math.random()*2+1)*(Math.random() > 0.5 ? -1 : 1)
					}
				}

			}
			
			
			
			/*
				bNoise is the key.
				
				we'll use perlinNoise to create a flame-like pattern
				then, we'll use this pattern fo fill bNoise, wich is higher then target.
				 
				we can later scroll bNoise and simulate flames moving up
			
			*/
			
			// create the bitmap
			bNoise = new BitmapData(30*30,20,true,0xFFFF0000);
			
			// fill bNoise with pattern
			box.width=30;
			box.height=30
			for (var start=0;start<20;start++) {
				box.x = start*30;
				bNoise.fillRect(box,0xFF0000 + ((20-start)*(255/20)<< 24))
				//bNoise.copyPixels(noise,noise.rect,origin,null,null,false)
			}
			box.x=0;
			box.width = conf.width;
			box.height = conf.height;
			
			// pattern not needed anymore
			
			
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
			set the amount of your object used as source of lite.
			you can use all (default) or just a region.
			
			for this to work, you choose a color channel, say RED, and
			define an interval, say 100 - 200.
			
			this way, only regions with RED value from 100 to 200 will emit lite
			 
			you choose color channel (RED,GREEN,BLUE) when creating the lite object
			for examples and better explanation see help.txt
			
			params:
			
			max,min: define interval from min to max.
			maxInc: if set, will be added to max at every step
			minInc: if set, will be added to max at every step
			delay: if set, and max=min, process delay frames than stop. 
		*/ 
		public function amount(max=0xFF,min=0,maxInc=0,minInc=0,delay=0) {
			lite.max = max * lite.mult;
			lite.min = min * lite.mult;
			lite.maxInc = maxInc * lite.mult; 
			lite.minInc = minInc * lite.mult;
			lite.active = true;
			if (delay > 0) {
				lite.end = true;
				lite.delay = delay;
			} else {
				lite.end = false;
			}
		}
		
		/*
		   this set lite power
		   pow: power from 0 to 100
		   powInc: if set, will be added to power at every step
		*/
		public function power(pow=85,powInc=0) {
			
			copyCT.alphaOffset = (pow>30) ? 127*pow/100 + 128 :  166*pow/30
			fadeCT.redMultiplier =  0.28*pow/100 + 0.6

			lite.pow = pow;
			
			if (pow == 0 && powInc <= 0) {
				lite.powInc = 0;
				lite.active = false;
				lite.delay=0
			} else {
				lite.powInc = powInc;
				lite.active = true;
			}
			
		}
		
		// do the magic
		public function update(e=null) {
		
		
			
		
			bDraw.fillRect(box,0) // lite mode
			bBuffer.fillRect(box,0)
			bDraw.draw(conf.target,null,null,null,box)
			
			
			//var bytes:ByteArray = bDraw.getPixels(r);
		
			var bx:uint=2
			var by:uint=16
			
			var r=new Rectangle(0,0,bx,by);
			
		
			var p=[0xFF0000FF,0xFFFF0000]
			var x:uint,y:uint,w:uint=conf.width,h:uint=conf.height
			var a:uint=0xFF0000FF,b:uint=2,c:uint=0;
			
			
			//bData.draw(shap,null,null,null,box)
			
			//var w=100
			//var h=100
			
			var p = new Point();
			
			for(x=0;x<w;x+=bx) {
				//r.x=x
				//bData.fillRect(r,0xFFFF0000)
				for(y=0;y<h;y+=by) {
					r.x = x
					r.y = y
					
					p.x = x*2-w/2
					p.y = y
					
					//if (p.x>(w) || p.x < 0 || p.y > (h) || p.y < 0) continue 
					
					
					bBuffer.copyPixels(bDraw,r,p,null,null,true)
					//bData.fillRect(r,0xFFFF0000)
					//r.y=y
					//a = bDraw.getPixel32(x,y)
					//a++
					//bData.setPixel32(x,y,a)
				}
			}
		
			bData.lock();
			bF = new BlurFilter(8,8,1);
			bData.copyPixels(bBuffer,box,origin)
			//bData.applyFilter(bBuffer,box,origin, bF);
			//bData.paletteMap(bData,box,origin,lite.colorMap.a,lite.colorMap.a,lite.colorMap.a,lite.colorMap.r)
			bData.unlock();
		
			return
			//bData.copyPixels(bNoise,box,origin,null,null,false)
			//return
		
			/*
			
				IMPORTANTE:
				
				usa bData.copyPixels(bDraw,box,origin,bData,origin,false)
					
				con l'effetto di luce come alpha source.
				 
				così puoi simulare una mask sfumata creata dalla luce stessa.
			
			*/
		
		
			
			//	rotating lite
				
			
			//	static lite 
				
			bDraw.fillRect(box,0) // lite mode
			bBuffer.fillRect(box,0) // lite mode
			//bDraw.draw(conf.target,null,null,null,new Rectangle(590/2-20,0,40,300))
			bDraw.draw(conf.target,null,null,null,box)
			
			
			
			
			
			//bData.applyFilter(bBuffer,box,origin, bF);
			//bData.paletteMap(bData,box,origin,lite.colorMap.a,null,null,lite.colorMap.r)
			
			//bBuffer.paletteMap(bBuffer,box,origin,lite.colorMap.a,null,null,lite.colorMap.r)
			//bData.applyFilter(bBuffer,box,origin, bF);
			
			bData.copyPixels(bDraw,box,origin,null,null,false)
			return
			
			//bDraw.draw(conf.target,null,null,null,new Rectangle(590/2-15,0,30,300))
			//bDraw.threshold(bDraw,box,origin,"<",0x202020,0,0xFFFFFF,false);
			
			//var gF = new GradientGlowFilter(conf.width,0,[0x000000,0x800000,0xFF0000],[0,.5,1],[0,120,255],64,64,1,1,"outer",false)
			// best
			var gF = new DropShadowFilter(conf.width,0, 0xFF0000,1,8,8,1,1,false,false,false)
			
			origin.x = -conf.width;
			bBuffer.applyFilter(bBuffer,box,origin, gF);
			origin.x = 0
			
			//bData.copyPixels(bDraw,box,origin,null,null,false)
			bData.paletteMap(bBuffer,box,origin,lite.colorMap.a,null,null,lite.colorMap.r)
		
			return
			
			/*
			var s=1
			var M=new Matrix(s,0,0,s,0,0)
			*/
			
			bDraw.fillRect(box,0) // lite mode
			
			//bDraw.draw(conf.target,null,copyCT,null,box)
			bDraw.draw(conf.target,null,null,null,box)
			//bDraw.threshold(bDraw,box,origin,"<=",0x030303,0,0xFFFFFF,false);
			
			
			//bBuffer.applyFilter(bDraw,box,origin, bF);
			//bDraw.applyFilter(bBuffer,box,origin, gF);
			
			//bBuffer.applyFilter(bBuffer,box,origin, bF);
			/*
			var d=20
			var pos=[
			[-d,-d],[0,-d],	[d,-d],
			[-d,+0],[d,0],
			[-d,+d],[+0,d],	[d,d],
			]
			bDraw.fillRect(box,0)
			for (var i=0;i<8;i++) {
				origin.x = pos[i][0]
				origin.y = pos[i][1]
				//bDraw.colorTransform(box,fadeCT)
				bDraw.copyPixels(bBuffer,box,origin,null,null,true)
			}
			
			//bDraw.applyFilter(bDraw,box,origin, bF);
			origin.x=0;
			origin.y=0;
			*/
			
			//bBuffer.applyFilter(bDraw,box,origin, bF);
			//bBuffer.threshold(bBuffer,box,origin,"<=",0x100000,0,0xFF0000,false);
			/*
			bDraw.fillRect(box,0) 
			//bDraw.draw(bBuffer2,null,null,"add",box)
			for (var i=0;i<1;i++) {
				//origin.x = x*20;
				//origin.y = y*20;
				//bDraw.colorTransform(box,fadeCT)
				bDraw.copyPixels(bBuffer,box,origin,null,null,true)
			}var bF = new BlurFilter(64,64,1);
			
			origin.x=0;
			origin.y=0;
			*/
			//for (var i=0;i<10;i++) bDraw.draw(bBuffer,null,null,null,box)
			
			
			//bDraw.copyPixels(bNoise,new Rectangle(0,idx,conf.width,conf.height),origin,bBuffer,origin,true)
			
			//bDraw.draw(conf.target,null,copyCT,"add",box)
			/*
				
				BevelFilter(distance,angle,highlightColor,highlightAlpha,shadowColor,shadowAlpha,blurX,blurY, 1, quality:int = 1, type:String = "inner", knockout:Boolean = false)
			*/
			//var gF = new BevelFilter(10,lite.angle+=5,0xFF0000,1.0,0xFF0000,1,64,64,2,1,"outer", false)
				
			/*
			var gF = new DropShadowFilter(0,0, 0xFF0000,1,64,64,1,1,false,false,true)
			bBuffer.applyFilter(bDraw,box,origin, gF);
			*/
			
			var gF = new DropShadowFilter(conf.width,0, 0xFF0000,1,64,64,1,1,false,false,false)
			//var gF = new GlowFilter(0xFF0000,1,256,256,1,1,false,true)
			//var gF = new GradientGlowFilter(conf.width,0,[0x000000,0x800000,0xFF0000],[0,.5,1],[0,120,255],32,32,1,1,"outer",false)
			//var gF = new BevelFilter(conf.width,0,0xFF0000,1.0,0xFF0000,1,64,64,1,1,"outer", false)
			
			origin.x = -conf.width;
			bBuffer.applyFilter(bDraw,box,origin, gF);
			origin.x = 0
			
			
			//var bF = new BlurFilter(64,64,1);
			//var gF = new BevelFilter(5,-lite.angle,0xFF0000,1.0,0xFF0000,1,32,32,1,1,"outer", false)
			
			//bBuffer2.applyFilter(bBuffer,box,origin, bF);
			
			/*
			//var gF = new GlowFilter(0xFF0000,1,32,32,1.5,1,true,false)
			var gF = new BevelFilter(10,lite.angle+=5,0xFF0000,1.0,0xFF0000,1,64,64,1,1,"outer", false)
			bBuffer.applyFilter(bDraw,box,origin, gF);
			//bBuffer.applyFilter(bBuffer,box,origin, gF);
			bBuffer.threshold(bBuffer,box,origin,"<=",0x01FFFF,0,0xFFFFFF,false);
			*/
			
			
		
			
			
			//
			//bBuffer.paletteMap(bBuffer,box,origin,lite.colorMap.r,lite.colorMap.a,lite.colorMap.a,lite.colorMap.a)
			bBuffer.paletteMap(bBuffer,box,origin,lite.colorMap.a,null,null,lite.colorMap.r)
			//var bF = new BlurFilter(64,64,1);
			
			//bBuffer2.applyFilter(bBuffer,box,origin, bF);
			
			
			bData.lock()
			//bData.paletteMap(bBuffer,box,origin,lite.colorMap.r,lite.colorMap.a,lite.colorMap.a,lite.colorMap.a)
			//bData.applyFilter(bDraw,box,origin, bF);
			//bData.copyPixels(bBuffer2,box,origin,null,null,false)
			//bData.copyPixels(bDraw,box,origin,null,null,false)
			bData.copyPixels(bBuffer,box,origin,null,null,false)
			bData.unlock();

			return
			with (lite) {
				// if lite is active
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
					// if user requested stopping lite, deactivate it
					if (max == min && end) active = false;
				} 
				if (minInc != 0) {
					min = Math.min(Math.max(min + minInc,0),max);
					// if max reached 0 or max, clear minInc
					minInc = (min == 0 || min == max) ? 0 : minInc
					// if user requested stopping lite, deactivate it
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
					// if lite is not active, and delay == 0, we have nothing to do
					if (delay == 0) return
					// else, countdown
					delay--
				}
			
			}
			
			// scroll up the drawing area 
			bDraw.scroll(0,-5)
			// fade out
			bDraw.colorTransform(box,fadeCT)
			// if lite is active, add bBuffer2
			if (lite.active) bDraw.draw(bBuffer2,null,null,"add",box)
					
			// use our colorMap
			bBuffer.paletteMap(bDraw,box,origin,lite.colorMap.r,null,null,lite.colorMap.a)
			
			bData.lock()
			// apply the blur filter to smooth things out 
			bData.applyFilter(bBuffer,box,origin, bF);
			bData.unlock();
		}
		
	}
}