/*

	Pure actionscript 3.0 spinner

*/
package bitfade.ui.spinners.engines { 
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	import bitfade.utils.*
	import bitfade.ui.spinners.Spinner
	
	public class Cube extends bitfade.ui.spinners.engines.Engine {
		
		/*
			default conf
		
			colors: 				 color gradient
			size: 					 size
			
			blurFilterSize:			 blur filter size
			
			CubeLineSize:			 cube line size
			CubeIntensity:			 cube intensity
			
			CubemotionBlur: 		 amount of cube motion blur
			
			RxIncr:					 cube rotation speed around X axis
			RyIncr:					 cube rotation speed around Y axis
			RzIncr:					 cube rotation speed around Z axis
			
			other parameters are internally used, don't change.
			
		*/
		public static var conf:Object = {
			//colors:[0x00000000,0x80008000,0xFF81CB00,0xFFFEF671],
			colors:[0,0xC0000000,0xFFFFFFFF],
			size:30,
			blurFilterSize: 2,
			
			CubeLineSize: 2,
			CubeIntensity: 1,
			CubeMotionBlur: .8,
			
			
			RxIncr: 0.04,
			RyIncr:0.1,
			RzIncr:0.07,
			
			countdown:100,
			Rx: 0,
			Ry: 0,
			Rz: 0,
			rotMax: 2*Math.PI
		};
		
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
		
		public static function register(s:bitfade.ui.spinners.Spinner):void {
			if (!_instance) _instance = new Cube()
			Engine.register(s)
		}
		
		override protected function build() {
			conf.half = conf.size/2
			
			origin = new Point(0,0);
			
			wboard = new Shape();
			
			with (conf) {
				fadeCT = new ColorTransform(0,0,0,CubeMotionBlur,0,0,0,0);
				bF = new BlurFilter(blurFilterSize,blurFilterSize,1)
			}
			
			var s = conf.half/2
			
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
			
			bData = new BitmapData(conf.size,conf.size,true,0);

			box = bData.rect
			bBuffer = bData.clone();
			
			colorMap = Colors.buildColorMap(conf.colors)
			
			//buildColorMap();
			
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
		
		// render loop
		override public function tick():void {
			if (registered == 0) return
			
			var half:Number = conf.half
			var p
			var i:uint
			
			
			for (i=0;i<points3d.length;i++) {
				p = rot3d(points3d[i],conf.Rx,conf.Ry,conf.Rz)
				points2d[i] = {
					x : p[0] + half,
   					y : p[1] + half
				}
			}
			
			conf.Rx = (conf.Rx + conf.RxIncr) % conf.rotMax
			conf.Ry = (conf.Ry + conf.RyIncr) % conf.rotMax
			conf.Rz = (conf.Rz + conf.RzIncr) % conf.rotMax
			
			var gfx:Graphics = wboard.graphics
			
			gfx.clear()
			gfx.lineStyle(conf.CubeLineSize,0,conf.CubeIntensity)
					
			var first:Boolean
			
			for each (var line in lines) {
				first=true
				for each (var pi in line) {
					p=points2d[pi]
					if (first) {
						gfx.moveTo(p.x,p.y)
						first=false
					} else {
						gfx.lineTo(p.x,p.y)
					}
					
				} 
   			}
			
			bBuffer.colorTransform(box,fadeCT)
			bBuffer.draw(wboard,null,null,null,box)
			
			bData.lock();
			bData.applyFilter(bBuffer,box,origin,bF)
			bData.paletteMap(bData,box,origin,null,null,null,colorMap)
			bData.unlock();	
		
		}
		
		override public function destroy():void {
			Run.reset(tick)
			bBuffer.dispose()
			wboard = undefined
			super.destroy()
		}
				
	}
}
/* commentsOK */