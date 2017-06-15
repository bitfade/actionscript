/*

	playlist video (local) player

*/
package bitfade.media.players.playlist {
	
	import bitfade.media.players.playlist.Player
	import bitfade.media.streams.*
	import bitfade.media.visuals.*
	
	import flash.system.Security
	
	import bitfade.utils.*
	
	public class Youtube extends bitfade.media.players.playlist.Player {
	
		// constructor
		public function Youtube(...args) {
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
			defaults.controls.zoom = false
			//playlistDefaults.
		}
		
		// gets called when external resources are loaded
		override protected function externalResourcesLoaded(resources:*,id:*=null,url:*=null):void {
			// not needed coz we'll load it only when needed
			// bitfade.utils.youtube.load(youtubePlayerLoaded)
			youtubePlayerLoaded()
		}
		
		// called when youtube player is loaded 
		protected function youtubePlayerLoaded() {
		
			// do we have a playlist ?
			if (playlistConf) {
				
				// yes, do we have defined items ?
				if (playlistConf.hasOwnProperty("item")) {
				
					// yes, check for which ones we need to fetch info from YouTube
					var queue:Array = []
			
					for each (var item:XML in playlistConf.item) {
						if (item.@id.toString() != "") {
							// queue item
							queue.push(item.@id)
							
						}
					}
					if (queue.length > 0) {
						trace("ID")
						// if we have queued items, request data
						bitfade.utils.Youtube.getInfo(youtubeInfoLoaded,queue)
						return
					} 
				} else {
					// no items, do we have to load a YouTube playlist ?
					if (playlistConf.@id) {
						// yes, do it
						bitfade.utils.Youtube.getPlaylist(youtubeInfoLoaded,playlistConf.@id.toString())
						return
					} 
				}
			} else {
				// no playlist, do we have to fetch data for single video ?
				if (conf.start.id) {
					// yes, do it
					bitfade.utils.Youtube.getInfo(singleYoutubeInfoLoaded,[conf.start.id])
					return
				}
			}
			initDisplay()
		}
		
		// got single video data
		protected function singleYoutubeInfoLoaded(info:XML) {
			var node:XML = addDefaultQuality(info.item[0])
			// set some values
			if (!conf.start.resource) conf.start.resource = node.@resource.toString()
			if (!conf.start.resourceHD) conf.start.resourceHD = node.@resourceHD.toString()
			if (!conf.start.cover) conf.start.cover = node.@cover.toString()
			if (!conf.start.caption) conf.start.caption = node.caption.toString()
			
			initDisplay()
		}
		
		// got multiple videos data
		protected function youtubeInfoLoaded(info:XML) {
			
			if (info) {
				var iNode:XML,pNode:XML
				var id:String
				
				for each (iNode in info.item) {
					// get id from the playlist entry
					id = iNode.@id.toString()
					// get xml node with same id, if any
					pNode = playlistConf.item.(attribute("id")==id)[0]
					
					if (pNode) {
						// add missing data from fetched data
						if (!pNode.hasOwnProperty("@resource")) pNode.@resource = iNode.@resource
						if (!pNode.hasOwnProperty("@cover")) pNode.@cover = iNode.@cover
						if (!pNode.hasOwnProperty("@thumb")) pNode.@thumb = iNode.@thumb
						if (!pNode.hasOwnProperty("caption")) pNode.caption = iNode.caption
						addDefaultQuality(pNode)
					} else {
						// add playlist entry
						playlistConf.appendChild(addDefaultQuality(iNode))
					}
					
				}
			} else {
				// we have no additional data 
				if (!playlistConf.hasOwnProperty("item")) {
					// if we are here, we have no playlist entries, so disable playlist
					playlistConf = null
					conf.controls.playlist = false
				}
			}
			
			initDisplay()
		}
		
		// add quality settings
		protected function addDefaultQuality(node:XML):XML {
			if (node.@id.toString()) {
				node.@resource = "youtube:"+conf.playback.quality+":"+node.@id 
				node.@resourceHD = "youtube:"+conf.playback.HDQuality+":"+node.@id
				node.@preview = "youtube:"+conf.playback.previewQuality+":"+node.@id
			}
			
			return node
		}
		
		override protected function createPlaylistControl() {
			playlistConf.video.@type = "Youtube"
			super.createPlaylistControl()
		}
		
		protected function includeStreamClass():void {
			var cs:bitfade.media.streams.Youtube
			var vs:bitfade.media.visuals.Youtube
		}
		
		override protected function evHandler(e:*):void {
			// skip all events whose target belongs to chromeless player 
			if (e.target.loaderInfo && loaderInfo.url != e.target.loaderInfo.url) return
			super.evHandler(e)
		}
		
		override protected function getVisualClass():String {
			return "bitfade.media.visuals.Youtube";
		}
	
	}
}
/* commentsOK */