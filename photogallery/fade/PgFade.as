package gl.photogallery.fade{ 
	import gl.photogallery.simple
	import flash.geom.*
	import flash.display.*
	import gs.TweenLite;
	import gs.easing.*;
	import gl.effects.reflect.refPlane;
	import flash.events.*;
	
	public class pgFade extends gl.photogallery.simple {
		
		function pgFade(args:Object){
			super(args);
			if (!args.tdelay) conf.tdelay=1; 
		}
		
		override public function hideImg(bMap) {
			TweenLite.to(bMap, conf.tdelay, {alpha:0,onComplete: function() {
				galleryMC.removeChild(bMap)
			}});
 		}
		
		override public function fadeIn(bMap) {
			bMap.alpha=0;
			TweenLite.to(bMap, conf.tdelay, {alpha:1});
		}
				
	}
}