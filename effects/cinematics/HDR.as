/*

	High Dynamic Range cinematic effect

*/
package bitfade.effects.cinematics {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.core.*
	import bitfade.effects.*
	import bitfade.utils.*
	
	import bitfade.data.*
	import bitfade.easing.*
	import bitfade.filters.*
	
	public class HDR extends bitfade.effects.cinematics.Cinematic  {
	
		// other bitmapDatas
		protected var bMask:BitmapData;
		protected var bHDR:BitmapData;
		protected var bAlpha:BitmapData;
		
		// for fadeIn/fadeOut
		protected var fadeInFactor:Number = 0
		protected var fadeOutFactor:Number = 0
		protected var translateFractor:Number = 0
		
		protected var lBoxes:Array
		
		
		// constructor
		public function HDR(t:DisplayObject = null) {
			super(t)
		}
		
		// crteate the effect
		public static function create(...args):Effect {
			return Effect.factory(bitfade.effects.cinematics.HDR,args)
		}
						
		override protected function build():void {
		
			defaults.color = "oceanHL"
			defaults.angle = 30
			defaults.zFrom = 200
			defaults.zTo = 200	
			defaults.hdr = true;
			
			defaults.targetZ = 0
			
			super.build()
			
			
		}
						
		// create bitmapDatas
		override protected function buildBitmaps():void {
		
			conf.areaX = 1
			conf.areaY = 1
			
			
			if (!conf.hdr) return
			
			super.buildBitmaps()
			
			bMap.blendMode = conf.blendMode
		}
						
		// set effects preferences
		public function glow(...args):Effect {
			
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
			
			worker = worker_glow
			
			target.alpha = 0
			bMap.alpha = 0
			
			// compute offsets
			var xo:uint = realWidth >> 1 
			var yo:uint = realHeight >> 1
			
			bMap.x += -xo
			bMap.y += -yo
			
			target.x += -xo
			target.y += -yo
			
			x += xo
			y += yo
			
			// set target z only if rotation or zoom is defined
			if (conf.targetZ != 0 && (conf.angle != 0 || conf.z != 0) ) {
				target.z = conf.targetZ
			}
			
			if (!conf.hdr) {
				return this
			}
			
			// create bitmapDatas
			bAlpha = bData.clone()
			bMask = bData.clone()
			bHDR = bitfade.filters.HDR.apply(new Bitmap(rasterizedTarget))
			
			// create boxes for image animation
			lBoxes = new Array()
			
			for (var i:uint = 0;i<3;i++) {
				lBoxes[i] = {
					xF : Math.random()*w,
					yF : Math.random()*h,
					xT : Math.random()*w,
					yT : Math.random()*h,
					w : Math.random()*w,
					h : Math.random()*h
				}
			}
			
			
			bMap.scrollRect = new Rectangle(16,16,w-32,h-32)
			bMap.x += 16
			bMap.y += 16
			
			return this
		}
		
		// do the magic!
		protected function worker_glow(time:Number):void {
			
			// compute timings
		 	var nTime:Number = (time*2-1) 
		 	
		 	var aTime:Number = 1-Math.abs(nTime)
		 	
		 	bMap.alpha = aTime > 0.3 ? 1 : aTime/0.3
		 	
		 	if (nTime < 0) {
		 		target.alpha = aTime < fadeInFactor ?  aTime / fadeInFactor : 1
		 	} else {
		 		target.alpha = aTime < fadeOutFactor ?  aTime / fadeOutFactor : 1
		 	}
		 		 	
		 	var movRatio:Number = bitfade.easing.Sine.Out(time,0,1,1)
		 	
		 	// apply rotation and zoom
		 	if (conf.angle != 0 || conf.zFrom != conf.zTo) {
		 		rotationY = movRatio*conf.angle
				z = conf.zFrom + (conf.zTo-conf.zFrom)*movRatio
		 	}
		 	
		 	
		 	if (!conf.hdr) return
			
			var ratio:Number = bitfade.easing.Quad.Out(time,0,1,1)
			
			
			bData.lock()
			// clean
			bAlpha.fillRect(box,(ratio*0xA0) << 24)
			
			bMask.fillRect(box,0)
			
			var lBoxX: uint
			var lBoxY: uint
			var lBoxW: uint
			var lBoxH: uint
			var lBox:Object
			
			var alphaValue:uint = 0xA0000000
			
			// move the boxes
			for (var i:uint = 0;i<3;i++) {
				
				lBox = lBoxes[i]
				
				lBoxX =  lBox.xF + ratio*(lBox.xT-lBox.xF)
				lBoxW =  lBox.w*ratio
				
				
				bMask.copyPixels(bAlpha,Geom.rectangle(0,0,lBoxW ,h),Geom.point(lBoxX,0),null,null,true)
				bMask.fillRect(Geom.rectangle(lBoxX,0,1,h),alphaValue)
				bMask.fillRect(Geom.rectangle(lBoxX+lBoxW,0,1,h),alphaValue)
				
				
				lBoxY =  lBox.yF + ratio*(lBox.yT-lBox.yF)
				lBoxH =  lBox.h*ratio
				
				bMask.copyPixels(bAlpha,Geom.rectangle(0,0,w,lBoxH),Geom.point(0,lBoxY),null,null,true)
				bMask.fillRect(Geom.rectangle(0,lBoxY,w,1),alphaValue)
				bMask.fillRect(Geom.rectangle(0,lBoxY+lBoxH,w,1),alphaValue)
				
				
			}
			
			bData.copyPixels(bHDR,box,Geom.origin,bMask,Geom.origin)
		
			bData.unlock()
			
				
		}
		
		// destroy effect
		override public function destroy():void {
			//Gc.destroy(target)
			super.destroy()
		}
		
		
	}
}
/* commentsOK */