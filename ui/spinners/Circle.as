/*

	Pure actionscript 3.0 circle spinner

*/
package bitfade.ui.spinners { 
	
	import bitfade.ui.spinners.Spinner
	import bitfade.ui.spinners.engines.Circle
	
	public class Circle extends bitfade.ui.spinners.Spinner {
		
		override protected function getSize():Number {
			return bitfade.ui.spinners.engines.Circle.conf.size
		}
		
		override protected function register():void {
  			bitfade.ui.spinners.engines.Circle.register(this)
  		}
  		
	}
}