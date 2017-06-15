/*

	configurable solid color background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import bitfade.utils.*
	
	import bitfade.ui.backgrounds.engines.*
			
	
	public class Solid extends Background {
	
		protected var bMap:Bitmap
		
		public function Solid(...args) {
			configure.apply(null,args)
		}
		
		override protected function init():void {
			super.init()
			
			graphics.beginFill(conf.color,1)
			graphics.drawRect(0,0,w,h)
			graphics.endFill()
			
			
		}
				
	}

}
/* commentsOK */