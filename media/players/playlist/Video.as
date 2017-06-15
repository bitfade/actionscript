/*

	playlist video (local) player

*/
package bitfade.media.players.playlist {
	
	import bitfade.media.players.playlist.Player
	import bitfade.media.streams.*
	import bitfade.media.visuals.*
	import bitfade.utils.*
	
	public class Video extends bitfade.media.players.playlist.Player {
	
		// constructor
		public function Video(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		override protected function overrideDefaults() {
			super.overrideDefaults()
			defaults.playback.type = "Video"
		}
		
		protected function includeStreamClass():void {
			var cs:bitfade.media.streams.Video
			var vs:bitfade.media.visuals.Video
		}
	
	}
}
/* commentsOK */