/*

	This class is used to play videos

*/
package bitfade.media.players {
	
	import bitfade.media.players.video
	import bitfade.media.visuals.*
	import bitfade.media.streams.*
	
	import bitfade.utils.*
	
	public class audioVideo extends bitfade.media.players.video {
	
		protected var useSpectrum:Boolean = false
	
		public function audioVideo(...args) {
			super(args[0],args[1],args[2],args[3])
		}
		
		
		// this gets called on ADDED_TO_STAGE
		override public function boot(...args):void {
			defaults.start.useSpectrum = false
			super.boot.apply(null,args)
		}
		
		
		// create visualizer
		override protected function createVisual():void {
			if (useSpectrum) {
				vid = new bitfade.media.visuals.spectrum(w,h)			
			} else {
				vid = new bitfade.media.visuals.video(w,h)
			}
		}
		
		// create control stream
		override protected function createStream():void {
		
			var ext:String = resource.substring(resource.lastIndexOf(".") + 1).toLowerCase()
			
			if (controlStream) controlStream.destroy()
			
			useSpectrum = false
			
			// select right controlStream
			switch (ext) {
				case "mp3":
					useSpectrum = true
					controlStream = new bitfade.media.streams.audio()
				break
				case "m4a":
					useSpectrum = true
				default:
					controlStream = new bitfade.media.streams.video()	
			}
			
			// force spectrum
			if (conf.start.useSpectrum) useSpectrum = true
			
			var redrawNeeded:Boolean = false
			
			// hide zoom control (not used) when using spectrum
			if (zoomControl && zoomControl.visible == useSpectrum) {
				zoomControl.visible = zoomCaption.visible = conf.controls.zoom = !useSpectrum
				redrawNeeded = true
			}
			
			// hide fullscreen control (too slow) when using spectrum
			if (fsControl && fsControl.visible == useSpectrum) {
				fsControl.visible = conf.controls.fullscreen = !useSpectrum
				redrawNeeded = true
			}
			
			if (redrawNeeded) resize(w,h)
			
			// add event listeners
			with (bitfade.utils.events) {
				add(controlStream,streamEvent.GROUP_PROGRESS,updateBar,this)
				add(controlStream,streamEvent.GROUP_PLAYBACK,streamEventHandler,this)
			}
		}
		
	}
}