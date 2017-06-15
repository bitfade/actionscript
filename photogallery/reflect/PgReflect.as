package gl.photogallery.reflect{ 
	import gl.photogallery.simple
	import flash.geom.*
	import flash.display.*
	import gs.TweenLite;
	import gs.easing.*;
	import gl.effects.reflect.refPlane;
	import flash.events.*;
	
	public class pgReflect extends gl.photogallery.simple {
		private var gradM:Matrix;
		private var rPlane:refPlane;
		
		function pgReflect(args:Object){
			args.padBottom=100
			super(args);
			gradM = new Matrix();			
		}
		
		override protected function init(e) {
			removeEventListener(Event.ADDED,init) 			
 			galleryMC = new Sprite();
    		addChild(galleryMC);
 			rPlane = new refPlane({target:galleryMC})
 			addChild(rPlane)
 			layout();
    		first()
    	
 		}
		
		override protected function layout(e=null) {
			super.layout(e);
			
			var rect = galleryMC.scrollRect 
			if (!rect) {
				rect = new Rectangle(0,0,conf.width,conf.height-conf.padBottom)
			} else {
				rect.width = conf.width
				rect.height = conf.height-conf.padBottom
			}
			
			galleryMC.scrollRect = rect;
			rPlane.init();
			
			graphics.clear();
			
			gradM.createGradientBox(conf.width, conf.height-150, Math.PI/2, 0, 0);
			
			graphics.beginGradientFill(
				GradientType.LINEAR, 
				[0x000050,0x000000], 
				[1, 1], 
				[0, 180], 
				gradM, 
				SpreadMethod.PAD
			);
				  
			graphics.drawRect(0, 0, conf.width, conf.height-150);
			
			
			gradM.createGradientBox(conf.width, 150, Math.PI/2, 0, conf.height-150);
			
			graphics.beginGradientFill(
				GradientType.LINEAR, 
				[0x888888,0x000000], 
				[1, 1], 
				[0, 100], 
				gradM, 
				SpreadMethod.PAD
			);
				  
			graphics.drawRect(0, conf.height-150, conf.width, 150);
			
			
			
		}
		
		override protected function initImg(img,bMap=null) {
			super.initImg(img,bMap);
		}
		
		override public function hideImg(bMap) {
			bMap.setRegistration(0,bMap.height)
			var origX = bMap.x
			TweenLite.to(bMap, 1, {alpha:1,rotation2:90,x:0,ease:Quad.easeOut,onComplete: function() {
				bMap.rotation2 = 0
				bMap.x = origX
				galleryMC.removeChild(bMap)
			}});
 		}
		
		override public function fadeIn(bMap) {
			var origX = bMap.x;
			//bMap.y = conf.height
			bMap.setRegistration(bMap.width,bMap.height)
			bMap.rotation2 = -90
			bMap.x = conf.width;
			TweenLite.to(bMap, 1, {alpha:1,rotation2:0,x:origX,ease:Expo.easeOut,onUpdate:refUpdate});
		}
		
		private function refUpdate() {
			rPlane.update();
		}
		
	}
}