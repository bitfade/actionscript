/*

	Back Light cinematic effect

*/
package bitfade.effects.cinematics {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.core.*
	import bitfade.effects.*
	import bitfade.raster.*
	import bitfade.utils.*
	
	import bitfade.data.*
	import bitfade.data.geom.*
	
	public class Backlight extends bitfade.effects.cinematics.Cinematic  {
	
		// hold lines
		protected var drawer:bitfade.raster.AAGradientLine
		protected var bLines:BitmapData
		protected var points:LinkedListPool
		
		// for fadeIn/fadeOut
		protected var fadeInFactor:Number = 0
		protected var fadeOutFactor:Number = 0
		protected var translateFractor:Number = 0
		
		// color map
		protected var colorMap:Array
		protected var nullV:Vector.<uint>
		
	
		// constructor
		public function Backlight(t:DisplayObject = null) {
			super(t)
		}
		
		// crteate the effect
		public static function create(...args):Effect {
			return Effect.factory(Backlight,args)
		}
						
		override protected function build():void {
		
			defaults.color = "oceanHL"
			defaults.maxLight = 25
			
			super.build()
			// line drawer
			drawer = new AAGradientLine()
		}
						
		// create bitmapDatas
		override protected function buildBitmaps():void {
			super.buildBitmaps()
			
			colorMap = Colors.buildColorMap(conf.color)
			
			bLines = Bdata.create(w,h,bLines)
			bMap.blendMode = conf.blendMode
		}
						
		// set effects preferences
		public function light(...args):Effect {
			
			var totalTime:Number = args[0]
			
			// compute fadeIn/fadeOut
			if (conf.fadeIn < 0) {
				conf.fadeIn = Math.min(1,totalTime*0.1)
			}
			
			if (conf.fadeOut < 0) {
				conf.fadeOut = Math.min(1,totalTime*0.1)
			}
			
			fadeInFactor = conf.fadeIn/totalTime
			fadeOutFactor = conf.fadeOut/totalTime
			
			translateFractor = Math.min(1,totalTime)
			
			// zeroed vector for reset lines
			nullV = bData.getVector(bData.rect)
			
			drawer.width = w
		 	drawer.height = h
			
			if (!points) {
				// create the points linked list as a single shared instance
				points = new LinkedListPool(Point2d,Single.instance("point2dStack",Stack))
			}
			
			// get edges points
			BitmapPoints.getEdges(rasterizedTarget,points)
			
			worker = worker_light
			
			target.alpha = 0
			
			return this
		}
		
		// do the magic!
		protected function worker_light(time:Number):void {
			
			// get first point
			var current:Point2d = Point2d(points.head.next)
			
			var w2:uint = w >> 1
			var h2:uint = h >> 1
			var xp:uint
			var yp:uint
		 	var dx:int
		 	var dy:int
		 	var fx:int
		 	var fy:int
		 	var d:int
		 	
		 	// compute timings
		 	var nTime:Number = (time*2-1) 
		 	
		 	var aTime:Number = 1-Math.abs(nTime)
		 	
		 	bMap.alpha = aTime > 0.3 ? 1 : aTime/0.3
		 	
		 	if (nTime < 0) {
		 		target.alpha = aTime < fadeInFactor ?  aTime / fadeInFactor : 1
		 	} else {
		 		target.alpha = aTime < fadeOutFactor ?  aTime / fadeOutFactor : 1
		 	}
		 	
		 	
		 	
		 	var tw2:int = rasterizedTarget.width >> 1
		 	var idx:int = int(-nTime*tw2*translateFractor+0.5)
		 	
		 	// compute max light power
		 	var maxLight:uint = uint(0xFF*Math.min(conf.maxLight,100)/100+0.5)
		 	var densityMult:uint = 400+(conf.maxLight > 100 ? conf.maxLight - 100 : 0)
		 	
		 	var max:uint = Math.min(maxLight,uint((densityMult*rasterizedTarget.width*rasterizedTarget.height)/(points.length << 6)))
		 	
		 	var maxD:uint = 150
		 	
		 	// effect's center
		 	var xo:int = int((w-rasterizedTarget.width) >> 1) + 0
		 	var yo:int = int((h-rasterizedTarget.height) >> 1) + 0
			
			// compute starting alpha
			var maxAlpha:uint = uint(max*((tw2-Math.abs(idx))/tw2)) 
			var posAlpha:uint = maxAlpha
			
			// zero vector (clean)
			drawer.target = nullV.concat()
			
			var count:uint = 0
			var pl:uint
			
			var areaX:uint = conf.areaX
			var areaY:uint = conf.areaY
			
			// for each point
			for (;current;current = Point2d(current.next)) {
			
				// compute starting point
				xp = xo + current.x
  				yp = yo + current.y
  				
  				// skip points outside computed box
  				if (xp >= w || yp >= h ) continue
  				
  				// compute deltas
  				dx = xp-w2+idx
  				
				dy = yp-h2
				
				// distance
				d = Math.sqrt(dx*dx+dy*dy)
				
				// skip far destinations
				if (d>maxD || Math.abs(dx)>maxD ) continue
				posAlpha = uint(maxAlpha*((maxD-d)/maxD)) << 24
				
				// skip almost null values
				if (posAlpha < 0x02000000) {
					continue
				}
				
				// destination point
				fx = xp+(dx*areaX)
				fy = yp+(dy*areaY)
				
				// draw line
				drawer.draw(xp,yp,fx,fy,posAlpha)
				
				posAlpha = (posAlpha >> 24) << 4
				if (posAlpha > 0xFF) posAlpha = 0xFF 
				
				//posAlpha = 0xFF
				
				pl = yp*w+xp
				drawer.target[pl] = posAlpha << 24
				
				
			}
			
			
			bData.lock()
			bLines.setVector(box,drawer.target)
			/*
			bData.setVector(box,drawer.target)
			bLines.colorTransform(box,new ColorTransform(1,1,1,0.6,0,0,0,0))
			bLines.copyPixels(bData,box,geom.origin,null,null,true)
			*/
			
			//bData.applyFilter(bLines,box,geom.origin,new DropShadowFilter(0,0,0,1,4,4,1,1,false,false,true))
			bData.applyFilter(bLines,box,Geom.origin,new BlurFilter(4,4,1))
		 	bData.paletteMap(bData,box,Geom.origin,null,null,null,colorMap)
			
			bData.unlock()
				
		}
		
		// destroy effect
		override public function destroy():void {
			// recycle points
			Single.remove("point2dStack")
			if (points) points.repool()
			
			if (bLines) {
				bLines.dispose()
				bLines = undefined
			}
			
			//Gc.destroy(target)
			super.destroy()
		}
		
		
	}
}
/* commentsOK */