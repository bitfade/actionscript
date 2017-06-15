/*

	Pure actionscript 3.0 cube spinner

*/
package bitfade.ui.spinners { 
	
	import bitfade.ui.spinners.Spinner
	import bitfade.ui.spinners.engines.Cube
	
	public class Cube extends bitfade.ui.spinners.Spinner {
	
		override protected function getSize():Number {
			return bitfade.ui.spinners.engines.Cube.conf.size
		}
	
		override protected function register():void {
  			bitfade.ui.spinners.engines.Cube.register(this)
  		}
  			
	}
}
/* commentsOK */