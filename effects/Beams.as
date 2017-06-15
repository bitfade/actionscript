/*
	This effect will add light beams to your objects
*/

package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class beams extends Sprite {
		// hold the effect
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// some BitmapDatas used for computing
		private var bDraw:BitmapData;
		private var bBuffer:BitmapData;
		
		// hold the alpha gradient used to draw beams
		private var bGradient:BitmapData;
		
		/*
		   default conf
		   colors: default gradient
		   autoUpdate: ... you guess it
		*/
		private var conf:Object = {
			colors:[0x00000000,0x80970017,0xA0FF8C00,0xFFFFF82D,0xFFFFFFFF],
			autoUpdate:true
			
		};
		
		// some ColorTransforms used for alter colors
		private var fadeCT:ColorTransform;
		
		// blur filter
		private var bF:BlurFilter
		
		// stuff
		private var inited:Boolean=false;
		private var box:Rectangle;
		private var br:Rectangle;
		private var origin:Point;
		private var bs:Point;
		private var bd:Point;
		
		// hold beams properties
		private var beam:Object = {
			center: {},
			width: 200,
			height: 200,
			max: 15,
			min: 5,
			steps: 20,
			maxSize:30
		};
		
		// Constructor
		function beams(opts:Object){
			
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
			
			// colorTrasform used to fade out the optional glow on target
			fadeCT = new ColorTransform(.5,0,0,.5,0,0,0,0);
						
			// create the colorMap
			beam.colorMap = {
				r:new Array(256),
				a:new Array(256)
			}
			
			// zero fill
			// init() will later call buildColorMap to create the gradient
			with(beam.colorMap) {
				for (var i=0;i<256;i++) {
					r[i]=0
					a[i]=0
				}
			}
			
			// blur filter
			bF = new BlurFilter(32,32,1);
			
			// some stuff
			origin = new Point(0,0);
			bs = new Point(0,0);
			bd = new Point(0,0);
			box = new Rectangle(0,0,conf.width,conf.height);
			br = new Rectangle(0,0,0,0);
						
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
					beam.colorMap.a[idx] = color;
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
			} else {
				// add the bitmap
				addChild(bMap)
			}
			
			// create the bitmaps	
			bData = new BitmapData(conf.width, conf.height, true,0x000000);
			bMap.bitmapData = bData;
			
			bDraw = bData.clone();
			bBuffer = bData.clone();
						
			// create the bitmap
			bGradient = new BitmapData(beam.steps*beam.maxSize,beam.maxSize,true,0xFFFF0000);
			
			if (inited) return
			
			with (beam) {
				var r = new Rectangle(0,0,maxSize,maxSize)
			
				for (var start=0;start<steps;start++) {
					r.x = start*maxSize;
					bGradient.fillRect(r,0xFF0000 + ((steps-start)*(0xFF/steps)<< 24))
				}
			
			
			}
			
			configure()
			glow()
			
			// build the gradient
			buildColorMap()
					
			// add handler for auto update, if needed
			if (conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;

		}
		
		
		
		/*
			configure beams
			
			params:
			
			count: beams number
			len: length from 0.1 to 10
			max: max size from 1 to 30
			min: min size from 1 to 30
			speed: ..speed
			width,height: light source area dimension
			
		*/ 
		public function configure(count=30,len=1,Max=15,Min=5,speed=4,width=null,height=null) {
			if (count !== null) beam.count = count
			if (len !== null) beam.lenght = beam.steps/len
			if (Max !== null) beam.max = Max
			if (Min !== null) beam.min = Min
			
			if (width !== null) beam.width = width
			if (height !== null) beam.height = height
			
			
			if (!beam.beams || beam.beams.length != beam.count ) beam.beams = new Array(beam.count);
			
			var cx = conf.width/2,cy = conf.height/2
			
			beam.center = {
				x: cx,
				y: cy
			}
			
			if (!beam.start) beam.start = {
				x: cx,
				y: cy
			}
			
			with (beam) {
				var w=beam.width,
					h=beam.height,
					sz = max-min,
					sp = speed-1,
					w2 = w/2,
					h2 = h/2
				
				beam.xmin = cx - w2;
				beam.xmax = cx + w2;
				beam.ymin = cy - h2;
				beam.ymax = cy + h2;
				
				for (var i=0;i<count;i++) {
					beam.beams[i] = {
						x: center.x+Math.random()*w-w2,
						y: center.y+Math.random()*h-h2,
						dx: Math.ceil(Math.random()*sp+1)*(Math.random() > 0.5 ? -1 : 1),
						dy: Math.ceil(Math.random()*sp+1)*(Math.random() > 0.5 ? -1 : 1),
						size: Math.ceil(Math.random()*sz+min)
					}
				}

			}
		}
		
		public function start(x = null,y = null) {
			with (beam) {
				start = {
					x: x ? x : center.x,
					y: y ? y : center.y
				}
			}
		}
		
		/*
		   this set glow amount 
		   
		   q: quantity from 0 (disabled) to 1 (full)
		*/
		public function glow(q=0.5) {
			fadeCT.alphaMultiplier = q
			fadeCT.redMultiplier = q
			beam.doGlow = (q > 0)
		}
		
		
		// Liang - Barsky Line Clipping Algorithm
		private function intersect(x1,y1,x2,y2):Object {
		
			var u:Array=[0,1]
			var p:Array=[x1-x2,x2-x1,y1-y2,y2-y1]
			var q:Array=[x1-x,x+conf.width-x1,y1-y,y+conf.height-y1]
			var r:Array=[0,0,0,0]
			
			var d={x1:x1,y1:y1,x2:x2,y2:y2}
			var i=0;
			
			// no intersection
			for (i=0;i<4;i++) {
				if (p[i] == 0 && q[i]<0) return d
			}
			
			for (i=0;i<4;i++) {
				if( p[i] != 0 ) {
                	r[i] = q[i]/p[i] ;
                	if( p[i] < 0 ) u[0] = Math.max(r[i],u[0]) else u[1] = Math.min(r[i],u[1]);
         		}
			}
			
			// no intersection
   			if( u[0] > u[1] ) return d
          
          	return {
	         	"x1": x1 + u[0] * p[1],
  	        	"y1": y1 + u[0] * p[3], 
          		"x2": x1 + u[1] * p[1],
          		"y2": y1 + u[1] * p[3]
          	}
		}
		
		// do the magic
		public function update(e=null) {
		
			// clear
			bDraw.fillRect(box,0) 
			bBuffer.fillRect(box,0) 
			
			// draw target
			bDraw.draw(conf.target,null,null,null,box)
			
			// init stuff
			with(beam) {
			
				if (doGlow) {
					// copy target
					bBuffer.copyPixels(bDraw,box,origin,null,null,false)
					bBuffer.colorTransform(box,fadeCT)
				}
				
				var sx,sy,ip
				var xMin = xmin,xMax = xmax,yMin = ymin,yMax = ymax
				var cx = start.x,cy = start.y
				var l=beam.lenght
			}
			
			// draw beams
			for (var i=0;i<beam.count;i++) {
				
				with (beam.beams[i]) {
					// move beam origin
					if (x < xMin || x > xMax ) dx=-dx;
					if (y < yMin || y > yMax ) dy=-dy;
					
					x += dx
					y += dy
					
					// clip beams outside container
					ip = intersect(x,y,x + (x-cx)*2,y + (y-cy)*2)
					
					// evaluate x,y increments
					sx = (ip.x2-x)/l
					sy = (ip.y2-y)/l
					
					bs.x = bd.x = x;
					bs.y = bd.y = y;
					
					br.width = br.height = size;
					br.x = 0;
				}
				
				for (var j=0;j<beam.steps;j++) {				
					bBuffer.copyPixels(bGradient,br,bd,bDraw,bs,true)
					br.x += beam.maxSize
					bd.x += sx
					bd.y += sy
				}
				
			}
			
			bData.lock()
			// smooth with blur filter
			bData.applyFilter(bBuffer,box,origin, bF);
			// use our colorMap
			bData.paletteMap(bData,box,origin,beam.colorMap.r,null,null,beam.colorMap.a)
			bData.unlock()			
		}
		
	}
}