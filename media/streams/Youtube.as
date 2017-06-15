/*

	This class handles video streams

*/
package bitfade.media.streams {
	
	import flash.display.*
	import flash.media.*
	import flash.net.*
	import flash.events.*
	import flash.utils.*
	import flash.system.Security
	
	import bitfade.utils.*
	
	public class Youtube extends bitfade.media.streams.Stream {
	
		public static const UNSTARTED:Number = -1;
		public static const ENDED:Number = 0;
		public static const PLAYING:Number = 1;
		public static const PAUSED:Number = 2;
		public static const BUFFERING:Number = 3;
		public static const CUED:Number = 5;
		
		// true if we have video metadata
		protected var gotMetaData:Boolean = false;
		
		// some timers
		protected var controlTimer:Timer
		
		protected var player:*
		
		// playback start time
		protected var startTime:uint;
		
		protected var startBytePos:int = -1
		
		protected var loading:Boolean = false;
		
		protected var destroyed:Boolean = false;
		
		// constructor
		public function Youtube() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Youtube");
		}
		
		public function get vid() {
			return player
		}
		
		override public function get type():String {
			return "Youtube"
		}
		
		
		// init flash.net stuff
		protected function initNet():void {
		
			// if inited, do nothing
			if (netInited || loading) return
			loading = true
			fireEvent(StreamEvent.INIT,getTimer())
			
			bitfade.utils.Youtube.load(youtubePlayerLoaded)
			
		}
		
		protected function youtubePlayerLoaded() {
			
			player = bitfade.utils.Youtube.getPlayer()
			
			if (destroyed) {
				return destroy()
			}
			
			if (!player) {
				errorText = "cannot load youtube player"
				fireEvent(StreamEvent.NET_ERROR,getTimer())
				return
			}
			
			Events.add(player,["onStateChange","onError","onPlaybackQualityChange","onCueRangeEnter","onCueRangeExit","NEXT_CLICKED","SIZE_CLICKED"],netHandler,this)
			
			// set up timers
			controlTimer = new Timer(100, 0);
            // add listeners
            bitfade.utils.Events.add(controlTimer,TimerEvent.TIMER,controlHandler,this)
			controlTimer.start()
			
			netInited = true
			loading = false
			
			fireEvent(StreamEvent.READY,getTimer())
			
			Commands.run(this)
			
			//if (queue) load.apply(null,queue)
			
		}
		
		// return if stream is ready to play
		override public function get ready():Boolean {
			return netInited
		}
		
		
		// no need to explain following methods, do i ?
		
		public function get bytesStart():uint {
			return netInited ? player.getVideoStartBytes() : 0
		}
		
		override public function get bytesLoaded():uint {
			return netInited ? player.getVideoBytesLoaded() : 0
		}
		
		override public function get bytesTotal():uint {
			return netInited ? player.getVideoBytesTotal() : 1
		}
		
		override public function get loaded():Number {
			return startBytePos == 0 ? bytesLoaded/bytesTotal : (bytesLoaded+startBytePos)/(bytesTotal+startBytePos)
		}
		
		override public function get time():Number {
			return netInited ? player.getCurrentTime() : 0
		}
		
		/*
		override public function get position():Number{
			return uint(1000*time/duration+0.5)/1000
		}
		*/
		
		// reset current stream, clean stuff and reinitializes some values
		override protected function reset():void {
			super.reset()

			startTime = 0
			gotMetaData = false
			startBytePos = -1
			
		}
		
		// gets called when we need to start loading the movie
		protected function streamStart():void {
			started = true
			
			var resProps:Object = splitResource("youtube","default",resource)
			var videoID:String
			var tokens = resProps.resource.match(/^http:\/\/www.youtube.com\/watch\?v=(\w+)/)
			
			if (tokens) {
				videoID = tokens[1]
			} else {
				videoID = resProps.resource
			}
			
			player.loadVideoById(videoID,0,resProps.quality)
			
			fireEvent(StreamEvent.CONNECT,getTimer())
		}
		
		// load a movie
		override public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {
			
			initNet()
			if (!netInited) {
				Commands.queue(this,load,url,startPaused,startBuffering)
				return
			}
			
			resource = url;
			
			initNet()
			reset()
			
			playedStreams++
			
			if (startBuffering) {
				// start movie loading now
				streamStart()
				paused = startPaused
			} else {
				// defer movie loading to first resume() call
				started = false
				paused = true
			}
			
			// pause (if needed)
			if (paused) player.pauseVideo()
			//netS.bufferTime = 0.2
		}
		
		// gets called when netStream got metadata from loading video
		public function onMetaData():void {
		
			if (gotMetaData) return
				
			gotMetaData = true
			
			
			width = player.width
			height = player.height
			
			fireEvent(StreamEvent.INFO,0)
			
        }
        
        // pause playback
		override public function pause():Boolean {
			if (paused || !netInited) return false
			paused = true;
			if (!buffering && !stopped) fireEvent(StreamEvent.PAUSE,time)
			player.pauseVideo()
			return true
		}
		
		// resume playback
		override public function resume():Boolean {
			if (started && (position == 1 && playStarted)) return false
			if (_resume()) {
				delete lastEventValue[StreamEvent.STOP]
				if (playStarted) {
					// not first time, fire a RESUME event
					fireEvent(StreamEvent.RESUME,time)
				} else {
					// first time, fire a PLAY event
					playStarted = true
					fireEvent(StreamEvent.PLAY,getTimer())
				}
				return true;
			}
			return false
		}
		
		// called by resume()
		protected function _resume():Boolean {
			if (!netInited) return false
			
			if (!started) {
				// if stream is not started, do it now
				streamStart()
			}
			
			
			/*
				this is due to a bug in chromeless player:
				when seeking near video end, calling a playVideo() 
				right after seekTo, freezes the player... DOH!!!
				
				setting a small delay (0.1s) seems to prevent the bug
			
			*/
			if (duration >0 && duration-time < 3) {
				Run.after(0.1,player.playVideo)
			} else {
				player.playVideo()
			
			}
		
			paused=false
			return true
		}
		
		
		// seek stream
		override public function seek(pos:Number,end:Boolean = true):Number {
			
			player.seekTo(duration*pos,end)
			if (status == 0) player.pauseVideo()
			
			
			fireEvent(StreamEvent.SEEK,uint(pos*1000+.5)/1000)
			
			if (pos > 0) stopped = false
			
			return pos
		}
		
		
		// this controls how stream is loading
		protected function controlHandler(e:Event):void {
		
			if (bytesLoaded > 0) {
				/*
				// if got bytes, fire STREAMING
				if (!lastEventValue[StreamEvent.STREAMING]) {
					fireEvent(StreamEvent.STREAMING,loaded,true)
				}
				*/
				// fire PROGRESS event
				
				fireEvent(StreamEvent.PROGRESS,loaded,true)
			}
		
			
			// fire POSITION event if playing
        	if (gotMetaData && (status == 1 || (status == 2 && paused)) ) {
        		
        		fireEvent(StreamEvent.POSITION,position,true)
        		
        	}
        	
        	updateStreamValues()
        	
        }
        
        protected function updateStreamValues() {
        	if (bytesTotal>1 && bytesStart != startBytePos) {
      			startBytePos = bytesStart
      			fireEvent(StreamEvent.START_POS,bytesStart/(bytesStart+bytesTotal))
      		}
        }
		
		
		// set volume
		override public function volume(vol:Number):void {
			super.volume(vol)
			if (!netInited) {
				Commands.queue(this,volume,vol)
				return
			}
			player.setVolume(Math.round(vol*100))
		}
		
		protected function get status():Number {
			return (netInited) ? player.getPlayerState() : -2
		}
		
		// netStream events handler
		protected function netHandler(e:Event):void {
			updateStreamValues()
			
			switch (e.type) {
				case "onStateChange":
				
					buffering = false
					
					if (bytesLoaded > 0 && !lastEventValue[StreamEvent.STREAMING]) {
						fireEvent(StreamEvent.STREAMING,loaded,true)
					}
					
					switch (status) {
						case PLAYING:
							duration = player.getDuration()
								
							if (!playStarted) {
								fireEvent(StreamEvent.PLAY,startTime)
								playStarted = true
							} else {
								fireEvent(StreamEvent.RESUME,time)
							}
							
						break;
						case BUFFERING:
							//buffering = true
							
							onMetaData()
							buffering = true
							
							//fireEvent(StreamEvent.BUFFERING,0,false)
							if (playStarted) fireEvent(StreamEvent.BUFFERING,0,false)
							
						break;
						case PAUSED:
							//fireEvent(StreamEvent.RESUME,time)
							/*
							if (!playStarted) {
								playStarted = true
								fireEvent(StreamEvent.STREAMING,time)
							}
							*/
							//if (position == 1) stop();
						break
						case ENDED:
							fireEvent(StreamEvent.PROGRESS,1,true)
        					fireEvent(StreamEvent.POSITION,1,true)
							stop()
						break
					}
				break;
				case "onPlaybackQualityChange":
				break
				case "onError":
					fireEvent(StreamEvent.NOT_FOUND,Object(e).data)
				break;
			}
		}
		
		// tell player to not use spinner on buffering events
        override public function get useSpinner():Boolean {
        	return false
        }
        
        // tell player this stream will not include buffer size in buffer events
        override public function get hasNumbericBuffer():Boolean {
        	return false
        }
        
         // tell player to inform when seeking is ended
        override public function get seekNeedsEnd():Boolean {
        	return true
        }
        
        override public function stop():void {
        	super.stop()
		}
        
        override public function destroy():void {
			if (loading) {
				destroyed = true
				return
			}
        
			if (player) {
				volume(0)
				player.pauseVideo()	
				player.stopVideo()
				bitfade.utils.Youtube.reuse(player)	
			}
			player = undefined
			super.destroy()
		}
			
	}
}
/* commentsOK */