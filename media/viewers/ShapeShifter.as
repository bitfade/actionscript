/*

	ShapeShifter slideshow

*/
package bitfade.media.viewers {
	
	import bitfade.media.viewers.Slideshow
	import bitfade.utils.*
	
	public class ShapeShifter extends bitfade.media.viewers.Slideshow {
	
	
		// constructor
		public function ShapeShifter(...args) {
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			configName = "shapeshifter"
		}
		
		
	
	}
}
/* commentsOK */