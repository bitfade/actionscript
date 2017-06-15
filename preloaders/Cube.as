/*

	Pure actionscript 3.0 cube preloader

*/
package bitfade.preloaders { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.text.*;
	
	public class cube extends Sprite {
		
		/*
			default conf
		
			x,y:					 Position, default is to auto center.
			colors: 				 color gradient
			size: 					 size
			
			blurFilterSize:			 blur filter size
			
			glowFilterSize: 		 glow filter size
			glowFilterMax:			 glow filter max intensity
			glowFilterStrenght: 	 glow filter strenght
			
			CubeLineSize:			 cube line size
			CubeIntensity:			 cube intensity
			
			CubemotionBlur: 		 amount of cube motion blur
			
			RxIncr:					 cube rotation speed around X axis
			RyIncr:					 cube rotation speed around Y axis
			RzIncr:					 cube rotation speed around Z axis
			
			ProgressLineSize:		 progress line size
			ProgressIntensity:		 progress intensity (not loaded)
			ProgressLoadedIntensity: progress intensity (loaded)
			
			debug:					 if true, use debug mode
			
			other parameters are internally used, don't change.
			
		*/
		private var conf:Object = {
			colors:[0x00000000,0x80008000,0xFF81CB00,0xFFFEF671],
			size:80,
			blurFilterSize: 2,
			glowFilterMax: 0.5,
			glowFilterSize: 18, 
			glowFilterStrenght: 3,
			
			CubeLineSize: 2,
			CubeIntensity: 1,
			CubeMotionBlur: .8,
			
			
			ProgressLineSize: 3,
			ProgressIntensity: .3,
			ProgressLoadedIntensity:1,
			
			RxIncr: 0.04,
			RyIncr:0.1,
			RzIncr:0.07,
			
			debug:false,
			countdown:100,
			bytesStart:0,
			loadIncr:1,
			
			loaded: 0,
			Rx: 0,
			Ry: 0,
			Rz: 0,
			rotMax: 2*Math.PI
		};
		
		
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bBuffer:BitmapData;
		private var wboard:Shape;
			
		
		private var points3d:Array
		private var points2d:Array
		private var lines:Array
		private var origin:Point
		private var box:Rectangle
		private var colorMap:Array;
		private var fadeCT:ColorTransform;
		private var bF:BlurFilter
		private var gF:GlowFilter
		
		
			
		// constructor
		public function cube(target,opts:Object=null){
			// get the conf
			if (opts) for (var p in opts) conf[p] = opts[p];
			
			conf.half = conf.size/2
			conf.margin = conf.ProgressLineSize+1
			conf.target = target
			conf.linfo = target.loaderInfo
			
			
			bMap = new Bitmap()
			origin = new Point(0,0);
			colorMap = new Array(256)
			
			wboard = new Shape();
			
			
			with (conf) {
				bytesStart = linfo.bytesLoaded
				fadeCT = new ColorTransform(0,0,0,CubeMotionBlur,0,0,0,0);
				bF = new BlurFilter(blurFilterSize,blurFilterSize,3)
				gF = new GlowFilter(0,glowFilterMax,glowFilterSize,glowFilterSize,glowFilterStrenght,3)
			}
			
			addEventListener(Event.ADDED,init)
		}
		
		// init stuff, gets called where the cube is added to the stage
		private function init(e:Event = null) {
			removeEventListener(Event.ADDED,init)
			conf.target.stop()
			
			layout();
			stage.addEventListener(Event.RESIZE,layout)
			
			
			addChild(bMap)
			
			var s = conf.half/2-5
			
			points3d=[
				[-s,s,s],
				[s,s,s],
				[s,-s,s],
				[-s,-s,s],
				[-s,s,-s],
				[s,s,-s],
				[s,-s,-s],
				[-s,-s,-s]
				
			]
			
			lines=[
				[0,1,2,3,0,4,5,6,7,4],
				[1,5],
				[2,6],
				[3,7]
			]
			
			for (var i:uint=0;i<points3d.length;i++) {
				points3d[i] = rot3d(points3d[i],0,Math.PI/4,Math.PI/4)			
			}
			
			points2d = new Array(points3d.length)
			
			// create empty bitmapDatas
			bData = new BitmapData(conf.size,conf.size,true,0x000000);
			bMap.bitmapData = bData;
			
			box = bData.rect
			
			bBuffer = bData.clone();
			
			buildColorMap();
			addEventListener(Event.ENTER_FRAME,update)
		}
		
		// fix positioning on resize
		private function layout(e:Event=null) {
			x=(conf.x ? conf.x : stage.stageWidth/2) -conf.half
			y=(conf.y ? conf.y : stage.stageHeight/2)-conf.half	
		}
		
		// static method, use this to instantiate the preloader
		public static function addTo(target:DisplayObjectContainer,conf=null):cube {
			if (!(conf && conf.debug) && target.loaderInfo.bytesLoaded == target.loaderInfo.bytesTotal) return null
			var cI = new cube(target,conf);
			target.addChild(cI)
			return cI
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
			
			maxAlpha: max alpha value
			
		*/
		public function buildColorMap() {
		
			var c=conf.colors
			
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
					color = (cur.a*conf.countdown/100) << 24 | cur.r << 16 | cur.g << 8 | cur.b;
					colorMap[idx] = color;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
		}
		
		// rotate a point
		private function rot3d(p,rx,ry,rz):Array {
			
			var y0:Number = p[1]*Math.cos(rx) + p[2]*Math.sin(rx)
   			var z0:Number = p[2]*Math.cos(rx) - p[1]*Math.sin(rx)  				
   			var x1:Number = p[0]*Math.cos(ry) - z0*Math.sin(ry)
    				
    		return [
    			x1*Math.cos(rz) + y0*Math.sin(rz),
    			y0*Math.cos(rz) - x1*Math.sin(rz),
    			z0*Math.cos(ry) + p[0]*Math.sin(ry)
    		]	
  		
		}
		
		// destructor
		private function destroy() {
			stage.removeEventListener(Event.RESIZE,layout)
			removeEventListener(Event.ENTER_FRAME,update)
			parent.removeChild(this)
			conf.target.play()
		}
		
		// main loop
		public function update(e=null) {
		
			var half:Number = conf.half
			var p
			var i:uint
			
			with (conf) {
				if (loaded<100) {
					if (debug) {
						loaded += loadIncr
					} else {
						loaded = (linfo.bytesLoaded-bytesStart)/(linfo.bytesTotal-bytesStart)*100
					}
				} else {
					if (countdown > 0) {
						countdown -= 2
					} else {
						if (debug == "loop") {
							countdown=100
							loaded = 0
						} else {
							destroy()
						}
					}
					buildColorMap()
				}
			}
			
			
			for (i=0;i<points3d.length;i++) {
				p = rot3d(points3d[i],conf.Rx,conf.Ry,conf.Rz)
				points2d[i] = {
					x : p[0] + half,
   					y : p[1] + half
				}
			}
			
			with (conf) {
				Rx = (Rx + RxIncr) % rotMax
				Ry = (Ry + RyIncr) % rotMax
				Rz = (Rz + RzIncr) % rotMax
			}
			
			with (wboard.graphics) {
				clear()
				lineStyle(conf.CubeLineSize,0,conf.CubeIntensity)
			}
					
			var first:Boolean
			
			for each (var line in lines) {
				first=true
				for each (var pi in line) {
					p=points2d[pi]
					with (wboard.graphics) {
						if (first) {
							moveTo(p.x,p.y)
							first=false
						} else {
							lineTo(p.x,p.y)
						}
					}
				} 
   			}
			
			bBuffer.colorTransform(box,fadeCT)
			bBuffer.draw(wboard,null,null,null,box)
			
			var rad=half-conf.margin
			var delta = (conf.loaded/100)*Math.PI/8;
			var angle = delta
			var cRad = rad/Math.cos(delta);
			
			
			with (wboard.graphics) {
				clear()
				lineStyle(conf.ProgressLineSize,0,conf.ProgressIntensity)
				drawCircle(half, half, rad) 
				lineStyle(conf.ProgressLineSize,0,conf.ProgressLoadedIntensity)
				moveTo(half,conf.margin)
			}
						
			for (i=0; i<8; ++i, angle += delta*2) {
				wboard.graphics.curveTo(
					half + Math.sin(angle)*cRad,
					half - Math.cos(angle)*cRad,
					half + Math.sin(angle+delta)*rad,
					half - Math.cos(angle+delta)*rad
				);
			}
			
			with (bData) {
				lock();
				applyFilter(bBuffer,box,origin,gF)
				draw(wboard,null,null,null,box)
				applyFilter(bData,box,origin,bF)
				paletteMap(bData,box,origin,null,null,null,colorMap)
				unlock();	
			}
		
		
		
		}
		
	}
}