/*

	Pure lightning fast actionscript 3.0 particles

*/
package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class particles extends Sprite {
		
		/*
			default conf
			
			colors: 		default colors
			maxParticles:	max total number of particles
			
			for emitter, see configure()
			
		*/
		private var conf = {
			colors: [0x000000FF,0xA05A5DFF,0xFFCCEAFC,0xFFFFFFFF],
			maxParticles: 3000,
			emitter: [
				{
					xa:		0,
					ya:		0.15,
					amin:	50,
					amax:	130,
					vmin:	5,
					vmax:	7,
					lmin:	80,
					lmax:	110,
					maxAdd:	10,
					delay:	0,
					max:	3000,
					disabled: false,
					stopped: false
				}
			],
			autoUpdate: true
		}
		
		
		private var emitter:Array
		private var emitIdx:uint=0
		private var colorMap:Array
		private var fadeCT:ColorTransform
		
		private var pIdx:uint=0
		private var px:Array
		private var py:Array
		private var pvx:Array
		private var pvy:Array
		private var pl:Array				 				 
		
		private var sinT:Array
		
		
		// Xorshift RNGs -> rw = random uint
  		private var rndX:uint=123456789
  		private var rndY:uint=362436069
  		private var rndZ:uint=521288629
  		private var rndW:uint=88675123
  		private var rndT:uint
		
		
		
		// bitmaps
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bBuffer:BitmapData;
		private var bPart:BitmapData
		
		// stuff
		private var w:uint=0
		private var h:uint=0
		private var origin:Point
		private var dst:Point
		private var box:Rectangle
		private var inited:Boolean=false;
		
		
		// constructor
		function particles(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			
			w=conf.width
			h=conf.height
			
			// this will contain final particles
			bMap = new Bitmap()
			
			colorMap = new Array(0xFF);
			
			origin = new Point(0,0);
			dst = new Point(0,0)
			box = new Rectangle(0,0,w,h);
			fadeCT = new ColorTransform(0,0,0,.95,0,0,0,0)
			
			sinT = new Array(720+90)
   			
   			var degToRad:Number = Math.PI/180
   			
   			for (var angle=-359;angle < 360+90;angle++) {
   				sinT[angle] = Math.sin(angle*degToRad)
   			}

			configure()
			
			if (conf.autoUpdate) init();
		}
		
		public function change(idx,opts) {
			for (var p in opts) {
				emitter[idx-1][p] = opts[p];
			}
		} 
		
		// init stuff
		public function init() {
			
			if (!inited) addChild(bMap)
			
			// create empty bitmapDatas
			bData = new BitmapData(w,h,true,0x000000);
			bMap.bitmapData = bData;
			
			bBuffer = bData.clone();
			
			
			for each (var item in ["px","py","pvx","pvy","pl"]) {
				this[item] = new Array(conf.maxParticles) 
   			} 
   			
   			buildColorMap()
			size()
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
		}
		
		/*
			this is used to configure emitters.
			
			each emitters has:
			
			max:		max number of particles
			x,y:		emitter position
			amin,amax:	angle range in degrees, only integer values (-360 .. 360 )
			xa,ya:		acceleration
			vmin,vmax:	starting velocity range
			lmin,lmax:	particle life range
			maxAdd:		max number of new particles to add at every update
			delay:		delay (in frames) between particles add
			stopped:	if true, no more particles from this emitter
			disabled:	if true, same as stopped + particles freeze and fade out
			
		*/
		public function configure(emitters:Array=null) {
			var currEmit:Object
			if (emitters === null) {
				emitter = conf.emitter
				currEmit = emitter[0]
				currEmit.x = w/2
				currEmit.y = h
				currEmit.countdown = 0
			} else {
				emitter = emitters
				for (emitIdx=0;emitIdx<emitter.length;emitIdx++) {
					currEmit = emitter[emitIdx]
					if (currEmit.countdown == null) currEmit.countdown=0
					if (currEmit.disabled == null) currEmit.disabled=false
					if (currEmit.stopped == null) currEmit.stopped=false
				}
			}
		}
		
		/*
			this set particle persistence
			
			p: from 0 (no tail) to 1 (infinite tail)
			
		*/
		public function persist(p=0.9) {
			fadeCT.alphaMultiplier = p
		}
		
		/*
			this set particle size and alpha
			
			ps = particle size from 4 to 32
			
			alpha1 = alpha value from 0 to 1 (center)
			alpha2 = alpha value from 0 to 1 (around center)
			alpha3 = alpha value from 0 to 1 (border)
		
		*/
		public function size(ps=8,alpha1=.2,alpha2=.2,alpha3=0) {
			
			var circle:Shape = new Shape();
			bPart = new BitmapData(ps,ps,true,0x000000);
			
			var gradM = new Matrix();
			gradM.createGradientBox(ps,ps,0,0,0);
			
			with (circle.graphics) {
				lineStyle(1,0,0);
				beginGradientFill(
					GradientType.RADIAL, 
					[0x000000,0x000000,0x000000], 
					[alpha1,alpha2,alpha3], 
					[0,32,255], 
					gradM, 
					SpreadMethod.PAD
				);
				drawCircle(ps/2,ps/2,ps/2)
				endFill()
			}
			
			bPart.draw(circle,null,null,null,bPart.rect)
			
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
			c is an array of colors
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
		 
		
		public function update(e=null) {
			//bBuffer.fillRect(box,0)
			bBuffer.colorTransform(box,fadeCT)
			
			var cp:Function = bBuffer.copyPixels;
			var cbox = bPart.rect
			
			var cl:uint
			var cx:Number
			var cy:Number
			var cvx:Number
			var cvy:Number

			
			var angle:int
			var v:Number;
			var ay:Number;
			var ax:Number;
				
			var xs:Number
			var ys:Number
				
				
			var aMin:Number
			var aMult:Number
				
			var vMin:Number
			var vMult:Number
				
			var lMin:Number
			var lMult:Number	
			
			var addCount:int
			var canAdd:Boolean
			var erase:Boolean
			var maxParticles:uint
			
			pIdx=0 
				
				
			for (emitIdx=0;emitIdx<emitter.length;emitIdx++) {
				
				with (emitter[emitIdx]) {
					
					erase = (disabled == true)
					
					addCount = maxAdd
					maxParticles += max
					
					
					xs = x
					ys = y
				
					ay = ya
					ax = xa
				
					aMin = amin
					aMult = (amax-amin)/0xFFFF
				
					vMin = vmin
					vMult = (vmax-vmin)/0xFFFF
				
					lMin = lmin
					lMult = (lmax-lmin)/0xFFFF
				
					
					if (!stopped && countdown == 0) {
						canAdd = true
						countdown = delay
					} else {
						canAdd = false
						countdown--
					}
					
				}
				
				
				
				for (;pIdx<maxParticles;pIdx++) {
					if (erase) {
						pl[pIdx] = 0
						continue
					}
					cl = pl[pIdx]
					
					if (cl>0) {
						cl--
						
						cx = px[pIdx]
						cy = py[pIdx]
						cvx = pvx[pIdx]
						cvy = pvy[pIdx]
						
						cx += cvx
						cy += cvy
						cvx += ax
						cvy += ay
						
						pl[pIdx] = cl
						px[pIdx] = cx
						py[pIdx] = cy
						pvx[pIdx] = cvx
						pvy[pIdx] = cvy
						
						if (cx>w || cx<0 || cy>h || cy<0) continue
						
						dst.x = uint(cx+0.5)
						dst.y = uint(cy+0.5)
						cp(bPart,cbox,dst,null,null,true)
						
						
					} else {
						if (!canAdd || addCount-- <= 0) continue
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						pl[pIdx] = uint((rndW & 0xFFFF)*lMult)+lMin
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						angle = uint((rndW & 0xFFFF)*aMult+aMin)
						rndT=(rndX^(rndX<<11));rndX=rndY;rndY=rndZ;rndZ=rndW;rndW=(rndW^(rndW>>19))^(rndT^(rndT>>8))
						v = (rndW & 0xFFFF)*vMult+vMin
						pvx[pIdx] = v*sinT[angle+90]
						pvy[pIdx]  = -v*sinT[angle]
						px[pIdx] = xs
						py[pIdx] = ys
					}
					
					
					
				}
				
			}
			bData.lock()
			bData.paletteMap(bBuffer,box,origin,null,null,null,colorMap)
			bData.unlock()
		
		}
		
	}
}