/*

	Pure lightning fast actionscript 3.0 rain

*/
package bitfade.fast { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*

	
	public class rain extends Sprite {
		
		/* 
			default conf
			
			mode: 
				1 - simple mode, just rain
				2 - object mode, draw your mc at configurable level
				3 - object/umbrella mode, draw your mc at configurable level + hides rain drops
				
			collisions: 
			
				for mode 2 or 3: if true, draw collisions between rain drops and target object
				
			targetLevel: 
			
				for mode 2 or 3: target level position from 1 to 5
				
			color: rain drop color
			autoUpdate: auto update rain
			speed: rain speed  for each plane
			max: max number of drops for each plane
			increment: number of drops to add at any update
			len: drops lenght for each plane
			alpha: drops starting alpha for each plane
			
			other values are internally used, don't change
			 
		*/
		private var conf:Object = {
			mode:1,
			collisions:false,
			targetLevel: 5,
			color: 0xFFFFFF,
			autoUpdate:true,
			speed:[12,15,18,20,22],
			max:[1500,1200,800,600,400],
			increment:0,
			len:[4,8,12,16,20],
			alpha:[0x10,0x08,0x05,0x05,0x05],
			pos: [0,0,0,0,0],
			n:[0,0,0,0,0],
			collY:[-1,-2,-2,-3,-3,-3,-3,-2,-1,0,1],
			planes:5
		};
		
		
		// bitmaps
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bRain:Array;
		private var bBuffer:BitmapData;
		private var bDraw:BitmapData;
		
		// stuff
		private var origin:Point
		private var dpt:Point;
		private var box:Rectangle
		private var sbox:Rectangle;
		private var fbox:Rectangle;
		private var inited:Boolean=false;
		
		
		// constructor
		function rain(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			// this will contain final rain
			bMap = new Bitmap()
			
			origin = new Point(0,0);
			dpt = new Point(0,0)
			box = new Rectangle(0,0,conf.width,conf.height);
			sbox = new Rectangle(0,0,conf.width,conf.height);
			fbox = new Rectangle(0,0,conf.width,conf.height);
			
			bRain=new Array(conf.planes);
			
			if (conf.autoUpdate) init();
		}
		
		
		
		// init stuff
		public function init() {
			
			if (!inited) addChild(bMap)
			
			var w:uint = conf.width
			var h:uint = conf.height
			
			conf.drops = new Array(w)
			
			
			// create empty bitmapDatas
			bData = new BitmapData(w,h,true,0x000000);
			bMap.bitmapData = bData;
			
			bBuffer = bData.clone();
			bDraw = bData.clone();
			
			for (var i=0;i<conf.planes;i++) bRain[i] = new BitmapData(w,h,true,0x000000);
			
			var alpha,c,j:uint,len:uint;
			
			conf.gradients = new Array(conf.planes) 
			
			// create drop gradient 
			for (i=0;i<conf.planes;i++) {
				alpha = conf.alpha[i]
				len = conf.len[i]
				conf.gradients[i] = new Array(len)
				c=conf.gradients[i]
				
				for (j=0;j<len;j++) {
					alpha += 2
					c[j] = (alpha << 24) + conf.color
				}
				
			}
			
			start()
			
			if (!inited && conf.autoUpdate) {
				inited = true;
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
		}
		
		public function setTarget(target,mode=2,level=5,collisions=true) {
			conf.target = target
			conf.mode = mode
			conf.targetLevel = level
			conf.collisions = collisions
		}
		
		// draw rain drops
		public function start() {
			var p:uint,x:uint,y:uint,j:uint,i:uint,len:uint
			var w:uint = conf.width,h:uint = w
			var ymin:uint,ymax:uint,incr:uint,c;
			
			for (i=0;i<conf.planes;i++) {
				if (conf.n[i] >= conf.max[i]) break
				
				c = conf.gradients[i]
				len = conf.len[i]
				
				incr = conf.increment>0 ? conf.increment : conf.max[i]
				
				conf.n[i] += incr
				
				for (p=0;p<incr;p++) {
					x = Math.random()*w
					y = Math.random()*h
					for (j=0;j<len;j++) {
						bRain[i].setPixel32(x,y+j,c[j])
					}
					bRain[i].setPixel32(x,y+j,c[len/2])
					bRain[i].setPixel32(x,y+j+1,c[len/4])
				}
			}
			
			
		} 
		
		public function update(e=null) {
		
			var py:int
			var mode:uint = conf.mode
			var targetLevel:uint = conf.targetLevel-1
			var collisions:Boolean = conf.collisions;
			var collY = conf.collY
			var drops = conf.drops
			
			var minAlpha:uint = 0x01 << 24
			var xp:uint,yp:uint,w:uint=conf.width,h:uint=conf.height
					
			
			var bTmp:BitmapData = mode == 3 ? bBuffer : bData
				
			// if incremental start, add more drops
			if (conf.increment > 0) start()
			
			bData.lock();
			
			// for each rain plane
			for (var i=0;i<conf.planes;i++) {
			
				// scroll plane
				with (conf) {
					py = pos[i];
					py -= speed[i]
				
				}
				
				if (py < 0) py += h
				
				conf.pos[i] = py
 				
 				sbox.y = py
				sbox.height = h - py
		
				bTmp.copyPixels(bRain[i], sbox, origin,null,null,i != 0)
				
				dpt.y = h - py
				sbox.y = 0
				sbox.height = py
			
				bTmp.copyPixels(bRain[i], sbox, dpt,null,null, i != 0)
				
				// if mode 2 or 3 and target object defined
				if (mode > 1 && i == targetLevel && conf.target) {
					
					// draw object
					bDraw.fillRect(box,0)
					bDraw.draw(conf.target)
					
					// if collisions or umbrella mode
					if (collisions || mode == 3) {
						
						// find target object upper bound
						for (xp=0;xp<w;xp += 4) {
							for (yp=0;yp<h;yp += 4) {
								if (bDraw.getPixel32(xp,yp) > minAlpha) {
														
									// add collision			
									if (collisions && drops[xp] == null && bTmp.getPixel32(xp,yp) > minAlpha) {
										drops[xp] = {y:yp-2,i:1}
									}
								
									// erase rain
									if (mode == 3) {
										with (fbox) {
											x = xp
											y = yp
											width = Math.random()+3
											height = h-yp
										}
										
										bTmp.fillRect(fbox,0)
									}
									
									break;
								}
							
							}
						}
					}
					
					// draw collision
					if (collisions) {
						var d,di:uint,dColor:uint,color:uint = conf.color
					
						for (xp=0;xp<w;xp++) {
							d = drops[xp]
							if (d) {
								di = d.i
								yp = d.y + collY[di]
								if (d.i == 12) {
									drops[xp] = null
									continue
								}
								dColor = ((0x50 - (di*4)) << 24) +  color
								bTmp.setPixel32(xp-(di >> 1),yp,dColor)
								bTmp.setPixel32(xp+di,yp,dColor)
								d.i++
							}
						}					
					}
					
					
					if (mode == 2) bTmp.copyPixels(bDraw,box,origin,null,null,true)
					
				}
				

			}
			
			
			if (mode == 3) {
				bData.copyPixels(bDraw,box,origin)
				bData.copyPixels(bBuffer,box,origin,null,null,true)
			} 
			
			bData.unlock();
		}
		
	}
}