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
	
	public class youtube extends bitfade.media.streams.stream {
	
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
		
		public var player:*
		
		// playback start time
		protected var startTime:uint;
		
		protected var startBytePos:int = -1
		
		// constructor
		public function youtube() {
			super()
		}
		
		override public function get type():String {
			return "youtube"
		}
		
		
		// init flash.net stuff
		protected function initNet():void {
		
			// if inited, do nothing
			if (netInited) return
			bitfade.utils.youtube.getPlayer(youtubePlayerLoaded)
		
			// set up timers
			controlTimer = new Timer(100, 0);
            // add listeners
            bitfade.utils.events.add(controlTimer,TimerEvent.TIMER,controlHandler,this)
			controlTimer.start()
		
		}
		
		protected function youtubePlayerLoaded(pl:*) {
			player = pl
			netInited = true
			events.add(player,["onStateChange","onError","onPlaybackQualityChange","onCueRangeEnter","onCueRangeExit","NEXT_CLICKED","SIZE_CLICKED"],netHandler,this)
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
			//player.loadVideoById("7befAtB3aIQ")
			//player.loadVideoById("-zvCUmeoHpw",0,"large")
			//player.loadVideoById("zh5FD2AePJ0",0,"hd1080")
			//player.loadVideoById("zh5FD2AePJ0",0,"small")
			player.loadVideoById("zh5FD2AePJ0",0,"hd720")
			//player.setPlaybackQuality("hd720")
			fireEvent(streamEvent.CONNECT,getTimer())
		}
		
		// load a movie
		override public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {
			
		
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
			
			// set values from event
			//fps = info.framerate ? info.framerate : info.videoframerate,
			
			/*
			trace(player)
			
			trace(player.width+"x"+player.height)
			trace(player.getAvailableQualityLevels())
			*/
			
			width = player.width
			height = player.height
			duration = player.getDuration()
			
			//fireEvent(streamEvent.INFO,fps)
			fireEvent(streamEvent.INFO,0)
			
        }
        
        // pause playback
		override public function pause():Boolean {
			if (paused) return false
			paused = true;
			if (!buffering && !stopped) fireEvent(streamEvent.PAUSE,time)
			player.pauseVideo()
			return true
		}
		
		// resume playback
		override public function resume():Boolean {
			if (started && (position == 1 && playStarted)) return false
			if (_resume()) {
				delete lastEventValue[streamEvent.STOP]
				if (playStarted) {
					// not first time, fire a RESUME event
					fireEvent(streamEvent.RESUME,time)
				} else {
					// first time, fire a PLAY event
					playStarted = true
					fireEvent(streamEvent.PLAY,getTimer())
				}
				return true;
			}
			return false
		}
		
		// called by resume()
		protected function _resume():Boolean {
			if (!started) {
				// if stream is not started, do it now
				streamStart()
			}
			
			player.playVideo()
			paused=false
			return true
		}
		
		
		// seek stream
		override public function seek(pos:Number,end:Boolean = true):Number {
			
			player.seekTo(duration*pos,end)
			fireEvent(streamEvent.SEEK,uint(pos*1000+.5)/1000)
			
			if (pos > 0) stopped = false
			
			return pos
		}
		
		
		// this controls how stream is loading
		protected function controlHandler(e:Event):void {
		
			if (bytesLoaded > 0) {
				// if got bytes, fire STREAMING
				if (!lastEventValue[streamEvent.STREAMING]) fireEvent(streamEvent.STREAMING,loaded,true)
				// fire PROGRESS event
				
				fireEvent(streamEvent.PROGRESS,loaded,true)
			}
		
			
			// fire POSITION event if playing
        	if (gotMetaData && status == 1) {
        		
        		fireEvent(streamEvent.POSITION,position,true)
        		duration = player.getDuration()
        	}
        	
        }
		
		
		// set volume
		override public function volume(vol:Number):void {
			if (!netInited) return
			player.setVolume(vol)
		}
		
		protected function get status():Number {
			return (netInited) ? player.getPlayerState() : -2
		}
		
		// netStream events handler
		protected function netHandler(e:Event):void {
			//trace(e.type,status)
			import bitfade.debug
			debug.log(e.type,Object(e).data)
			switch (e.type) {
				case "onStateChange":
					buffering = false
					switch (status) {
						case PLAYING:
							if (!playStarted) {
								fireEvent(streamEvent.PLAY,startTime)
								playStarted = true
							} else {
								fireEvent(streamEvent.RESUME,time)
							}
							if (bytesTotal>1 && bytesStart != startBytePos) {
        						startBytePos = bytesStart
        						fireEvent(streamEvent.START_POS,bytesStart/(bytesStart+bytesTotal))
        					}
						break;
						case BUFFERING:
							buffering = true
							onMetaData()
							fireEvent(streamEvent.BUFFERING,0,false)
							//trace(e.type,status,player.getDuration(),player.width,player.height)
							
						break;
					}
					
					//player.playVideo()
				break;
				case "onPlaybackQualityChange":
					//trace(player.getPlaybackQuality())
					//fireEvent(streamEvent.NOT_FOUND,getTimer())
				break
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
        
       
		override public function destroy():void {
			super.destroy()
		}
			
	}
}
/* commentsOK */