/*

	Universal player

*/
package bitfade.media.players.playlist {
	
	import bitfade.media.streams.*
	import bitfade.media.visuals.*
	import bitfade.media.preview.playlist.*
	
	
	import bitfade.utils.*
	
	public class Universal extends bitfade.media.players.playlist.Youtube {
	
		// constructor
		public function Universal(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// override conf defaults
		override protected function overrideDefaults() {
			super.overrideDefaults()
			defaults.playback.type = "Youtube"
			defaults.playback.quality = "default"
			defaults.playback.HDQuality = "hd720"
			defaults.playback.previewQuality = "small"
			defaults.controls.zoom = true
			defaults.controls.show = "over"
			
			includeStreamClass()
		}
		
		// this create the playlist component
		override protected function createPlaylistControl() {
			playlistConf.video.@type = "Video"
			playlist = new bitfade.media.preview.playlist.Video(w,h,playlistConf)
		}
		
		override protected function includeStreamClass():void {
			// include code for all supported stream types
			super.includeStreamClass()
			bitfade.media.streams.Video.addClass()
			bitfade.media.streams.Rtmp.addClass()
			bitfade.media.streams.Youtube.addClass()
			bitfade.media.streams.Audio.addClass()
			bitfade.media.streams.Spectrum.addClass()
			bitfade.media.streams.Spectrumvideo.addClass()
			bitfade.media.streams.Beattrails.addClass()
			bitfade.media.streams.Beattrailsvideo.addClass()
			
			var vv:bitfade.media.visuals.Video
			var rv:bitfade.media.visuals.Rtmp
			var mv:bitfade.media.visuals.Spectrum
			var lv:bitfade.media.visuals.Beattrails
			
		}
		
		override protected function getVisualClass():String {
			return "bitfade.media.visuals."+controlStream.type;
		}
		
		// set visualizer
		override protected function setVisual():void {
			super.setVisual()
			if (vid) {
					if (vid is bitfade.media.visuals.Youtube) {
					// FIX FOR YOUTUBE GOOGLE ADDS
					onTop.mouseEnabled = false
					vid.mouseEnabled = vid.mouseChildren = true
					if (description) {
						description.mouseEnabled = false
					}
				} else {
					onTop.mouseEnabled = true
					if (description) {
						description.mouseEnabled = true
					}
				}
			}
			
		}
	
	}
}
/* commentsOK */