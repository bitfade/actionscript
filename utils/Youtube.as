/*
	helper class for youtube chromeless player / data api
*/
package bitfade.utils { 

	public class Youtube {
		
		import bitfade.utils.*
		import flash.display.*
		import flash.events.*
		import flash.net.*
		import flash.system.*
		import flash.utils.*
		
		protected static const PLAYER_URL:String = "http://www.youtube.com/apiplayer?version=3"
		protected static const PLAYLIST_URL:String = "http://gdata.youtube.com/feeds/api/playlists"
		protected static const PLAYLIST_MAX:uint = 50
		protected static const BATCH_URL:String = "http://gdata.youtube.com/feeds/api/videos/batch"
		protected static const BATCH_MAX:uint = 50
		
		protected static var loaderInstances:Dictionary
		protected static var players:Array
		
		protected static var delayedDestroy:*
		
		protected var playlistID:String;
		protected var queue:Array
		protected var result:XML
		protected var loader:Loader
		protected var callBack:Function
		protected var tmpPlayer:*
		protected var delayedCheck:RunNode
		protected static var killPlayerLoop:RunNode
		
		public function Youtube() {
		}
		
		
		protected static function getInstance():Youtube {
			if (!loaderInstances) loaderInstances = new Dictionary()
			var instance:Youtube = new Youtube();
			loaderInstances[instance] = instance
			return instance
		}
		
		public static function load(cb:Function):void {
			
			if (killPlayerLoop == null) {
				killPlayerLoop = Run.every(0.1,killTheDamnPlayers)				
			}
		
			if (players && players.length > 0) {
				cb()
			} else {
				getInstance().load(cb)
			}
		}
		
		public static function getInfo(cb:Function,ids:Array):void {
			getInstance().getInfo(cb,ids)
		}
		
		public static function getPlaylist(cb:Function,id:String):void {
			getInstance().getPlaylist(cb,id)
		}
		
		public static function getPlayer():* {
			return (players && players.length > 0) ? players.pop() : undefined
		}
		
		
		public function load(cb:Function = null) {
		
			callBack = cb
			
			Security.allowDomain("*")
			loader = new Loader();
			Events.add(loader.contentLoaderInfo,[Event.INIT,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR],playerLoaded)
			
			try {
				loader.load(new URLRequest(PLAYER_URL));
            } catch (e:*) {
            	playerLoaded(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR))
            }
			
		}
		
		public function getInfo(cb:Function,ids:Array) {
			callBack = cb
			queue = ids.concat()
			getLoop()
		}
		
		public function getPlaylist(cb:Function,id:String) {
			callBack = cb
			queue = []
			playlistID = id;	
			playlistLoop(1)
		}
		
		protected function playlistLoop(start:uint) {
			var request:URLRequest = new URLRequest(PLAYLIST_URL+"/"+playlistID+"?v=2&max-results="+PLAYLIST_MAX+"&start-index="+start);
			var loader:URLLoader = new URLLoader();
			Events.add(loader,[Event.COMPLETE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR],infoLoaded)
			
			try {
				loader.load(request)
            } catch (e:*) {
            	infoLoaded(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR))
            }
			
		}
		
		protected function getLoop() {
			var request:URLRequest = new URLRequest(BATCH_URL);

			var feed:XML = <feed 
          		xmlns="http://www.w3.org/2005/Atom" 
           		xmlns:batch="http://schemas.google.com/gdata/batch" 
       		 	xmlns:yt="http://gdata.youtube.com/schemas/2007">
            	<batch:operation type="query"/>
           	</feed>

			var el:String
			var max:uint = BATCH_MAX

			// create the batch request, no more then BATCH_MAX ids 
			while (max > 0 && queue.length > 0) {
				max--
				el = queue.shift()
				feed.appendChild(<entry><id>http://gdata.youtube.com/feeds/api/videos/{el}</id></entry>)
			}

			// set variables for request
			request.method = URLRequestMethod.POST;
			request.data = feed.toString()
            
            // run it
            var loader:URLLoader = new URLLoader();
            Events.add(loader,[Event.COMPLETE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR],infoLoaded)
            try {
            	loader.load(request)
            } catch (e:*) {
            	infoLoaded(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR))
            }
			
		}
		
		// called when api call ends
		protected function infoLoaded(e:Event):void {
		
			
			// remove the listener
			//e.target.removeEventListener(Event.COMPLETE, infoLoaded);
			Events.remove(e.target)
			
			if (e.type == IOErrorEvent.IO_ERROR || e.type == SecurityErrorEvent.SECURITY_ERROR) {
				callBack(undefined)
		
				return
			}
			
			// get the data
			var feed:XML = XmlParser.clean(new XML(e.target.data));
			
			
			// we have a previous result set ?
			if (!result) {
				// no, this is the first one
				result = feed
			} else {
				// yes, append
				result.appendChild(feed.children())
			}
			
			// now, we check if queue still holds other ids
			if (queue.length > 0) {
				// yes, request them
				getLoop()
			} else {
				// check if playlist has more pages
				if (result.hasOwnProperty("totalResults")) {
					
					// get some values
					var total:Number = parseFloat(result.totalResults.toString())
					var page:Number = parseFloat(result.itemsPerPage.toString())
					var start:Number = parseFloat(result.startIndex.toString())
				
					// we need to delete them from result set or we'll have duplicates 
					delete result.totalResults
					delete result.itemsPerPage
					delete result.startIndex
				
					start += page
					
					if (start <= total) {
						// yes, more pages
						playlistLoop(start)
						return
					}
				} 
			
				// no, we're done, parse result set and call callBack
				result = parseFeed(result)
				delete loaderInstances[this]
				callBack(result)
			}
        }

		// parse feed
		protected function parseFeed(input:XML):XML {
		
			//input = xmlParser.clean(input)
			
			// create the result object
			var result:XML = new XML(<playlist type="youtube"></playlist>)
			var id:String,title:String,description:String,caption:String
			
			var accessControl:XML
			
			for each (var node:XML in input.entry) {
			
				
				// skip entries which can't be played 
				if (!node.group.hasOwnProperty("content")) {
					continue;
				}
				
				// skip entries which doesn't allow embed 
				accessControl = node.accessControl.(attribute("action")=="embed")[0]
				if (accessControl && accessControl.@permission.toString() != "allowed") {
					continue;
				}
				
				// get some tags
				id = node.group.videoid.toString()
				
				if (!id) id = node.id.toString().replace(/.+\/(\w+)/,"$1")
				
				// remove strange chars from video id
				id = id.replace(/videos\//,"")
				
				title = node.group.title.toString()
				description = node.group.description.toString().replace(/\n/g,"<br/>")
				
				// get thumbnail and cover image
				var min:Number = uint.MAX_VALUE
				var max:Number = -1
				var width:Number = 0
				
				var cover:String = ""
				var thumb:String = ""
				
				for each (var img:XML in node.group.thumbnail) {
					if ((width = parseFloat(img.@width)) < min) {
						min = width
						thumb = img.@url
					}
					
					if ((width = parseFloat(img.@width)) > max) {
						max = width
						cover = img.@url
					}
				
				}
				
				// create result node
				node = <item
					id={id}
					resource={id}
				>
				</item>
				
				if (cover) node.@cover = cover
				if (cover) node.@thumb = thumb
				
				// add caption
				node.appendChild("<caption><![CDATA[<title>"+title+"</title><description>"+description+"</description>]]></caption>")
				// add node to result set
				result.appendChild(node)	
			}
			
			return result
					
		}
		
		// called when player is loaded
		protected function playerLoaded(e:Event) {
		
			Events.remove(e.target)
			
			if (e.type == IOErrorEvent.IO_ERROR || e.type == SecurityErrorEvent.SECURITY_ERROR) {
				delete loaderInstances[this]
				callBack()				
				return
			}
		
			
			//e.target.removeEventListener(Event.INIT, playerLoaded)		
			tmpPlayer = e.target.content
			loader.unload()
			Events.add(tmpPlayer,["onReady"],playerReady)
			delayedCheck = Run.after(30,playerReady)
		}
		
		
		// called when player is ready
		protected function playerReady(e:Event = null) {
		
			Run.reset(delayedCheck)
			Events.remove(tmpPlayer)
			
			if (e) reuse(tmpPlayer)
			
			tmpPlayer = undefined
			delete loaderInstances[this]
			callBack()
			
		}
		
		protected static function killTheDamnPlayers(e:Event = null) {
			if (players) {
				for (var i:uint = 0; i<players.length;i++) {
					if (players[i].getPlayerState() != -1) {
						players[i].stopVideo()
					}
				}
			}
		}
		
		// set a player available
		public static function reuse(player:*) {
			if (players) {	
				players.push(player)
			} else {
				players = [player]
			}
			delayedDestroy=Run.after(60,destroy,delayedDestroy)
		}
		
		// destroy unused players
		protected static function destroy() {
			for each (var pl in players) {
				delete players[pl]
				pl.destroy()
			}
			Run.reset(killPlayerLoop)
			killPlayerLoop = undefined
			delayedDestroy = undefined
			players = undefined
		}
		
	}
}
/* commentsOK */