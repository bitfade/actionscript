/*

	This class is used display a spectrum

*/
package bitfade.media.visuals {
	
	import flash.display.*
	import flash.geom.*
	import flash.events.*
	import flash.utils.*
	import flash.media.*
	import flash.filters.*
	
	import bitfade.intros.backgrounds.*
	import bitfade.utils.*
	
	public class Beattrails extends bitfade.media.visuals.Visual {
		
		// light trails background
		protected var lightBeat:bitfade.intros.backgrounds.BeatTrails
		
		// black background
		protected var background:Shape;
		
		// constructor
		public function Beattrails(w:uint=0,h:uint=0) {
			super()
			init()
			resize(w,h)
		}
		
		// init the spectrum
		protected function init():void {
			
			background = new Shape();
			addChild(background)
			
		}
		
		// scale spectrum
		override protected function scale():void {
			// if no size, do nothing
			if (maxW == 0 && maxH == 0) return
			
			background.graphics.beginFill(0,1)
			background.graphics.drawRect(0,0,maxW,maxH)
			background.graphics.endFill()
			
			if (lightBeat) {
				lightBeat.destroy()
			} 
			
			lightBeat = new bitfade.intros.backgrounds.BeatTrails(maxW,maxH)
			addChild(lightBeat)
			lightBeat.start()
			
		}
		
		// pause the visual
		override public function pause():void {
			if (lightBeat) lightBeat.pause()
			super.pause()
		}
			
		// pause the visual
		override public function resume():void {
			if (lightBeat) lightBeat.resume()
			super.resume()
		}
			
		// clean up
		override public function destroy():void {
			super.destroy()
		}
				
	}


}