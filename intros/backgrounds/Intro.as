/*

	configurable gradient background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import bitfade.utils.*
	
	import bitfade.ui.backgrounds.engines.*
			
	
	public class Intro extends Background {
	
		protected var bMap:Bitmap
		
		public function Intro(...args) {
			configure.apply(null,args)
		}
		
		override protected function init():void {
			super.init()
			
			bMap = new Bitmap()
			
			var colors:Array
			
			if (conf.color && conf.color2) {
				colors = [conf.color,conf.color2]
			}
			
			var style: String = conf.style == "light" ? "light" : "dark"
			
			Snapshot.take(bitfade.ui.backgrounds.engines.Intro.create(style,w,h,colors),bMap)
			
			addChild(bMap)
			
		}
				
	}

}
/* commentsOK */