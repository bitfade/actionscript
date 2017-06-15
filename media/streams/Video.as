/*

	This class handles video streams

*/
package bitfade.media.streams {
	
	import flash.display.*
	import flash.media.*
	import flash.net.*
	import flash.events.*
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Video extends bitfade.media.streams.Stream {
	
		// needed net.* stuff
		protected var netC:NetConnection
		protected var netS:NetStream
		
		// true if we have video metadata
		protected var gotMetaData:Boolean = false;
		
		// true if we got a "FULL" event from netStream
		protected var gotFull:Boolean
		
		// true if user forward seek
		protected var seekedForward:Boolean
		
		// some timers
		protected var controlTimer:Timer
		protected var bufferTimer:Timer
		protected var fixUnbufferedSeekTimer:Timer
		
		// used to fire good current buffer loaded values
		protected var bufferNormalizer:Number = 1;
		protected var bufferTimeStart:uint = 0;
		protected var lastBufferEventValue:Number = 0
		
		// playback start time
		protected var startTime:uint;
		
		protected var netStweakBuffer:Boolean = true
		
		// constructor
		public function Video() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Video");
		}
		
		override public function get type():String {
			return "Video"
		}
		
		
		// init flash.net stuff
		protected function initNet():void {
		
			// if inited, do nothing
			if (netInited) return
			
			netInited = true
		
			// create NetConnection and NetStream objects
			netC = new NetConnection();
			netC.connect(null);
			
			createNetS()			
		}
		
		protected function createNetS():void {
			netS = new NetStream(netC);
			netS.bufferTime = preloaded ? 10000 : 2 // new 
			
			// set up timers
			controlTimer = new Timer(100, 0);
            bufferTimer = new Timer(100, 1);
            fixUnbufferedSeekTimer = new Timer(50, 0);
                        
            // add listeners
            with (bitfade.utils.Events) {
            	add(netS,[
					AsyncErrorEvent.ASYNC_ERROR,
					NetStatusEvent.NET_STATUS
				], netHandler,this)
				add(controlTimer,TimerEvent.TIMER,controlHandler,this)
				add(bufferTimer,TimerEvent.TIMER,fillBuffer,this)
				add(fixUnbufferedSeekTimer,TimerEvent.TIMER,fixUnbufferedSeek,this)
			}
            
            netS.client = this
			controlTimer.start()
		}
		
		// return if stream is ready to play
		override public function get ready():Boolean {
			return netInited
		}
		
		
		// uset to get netStream object
		public function get netStreamObject():NetStream {
			return netS
		}
		
		// no need to explain following methods, do i ?
		
		override public function get bytesLoaded():uint {
			return netInited ? netS.bytesLoaded : 0
		}
		
		override public function get bytesTotal():uint {
			return netInited ? netS.bytesTotal : 1
		}
		
		override public function get time():Number {
			return netInited ? netS.time : 0
		}
		
		// reset current stream, clean stuff and reinitializes some values
		override protected function reset():void {
			super.reset()

			if (netS) {
				netS.pause()
				netS.close()
			}
			//netS.bufferTime = 0.2
			
			startTime = 0
			seekedForward = gotFull = gotMetaData = false
			
		}
		
		// gets called when we need to start loading the movie
		protected function streamStart():void {
			if (!netS) return
			started = true
			netS.play(ResLoader.absoluteUrl(resource))
			fireEvent(StreamEvent.CONNECT,getTimer())
		}
		
		// load a movie
		override public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {
			resource = Stream.getResourceFrom(url);
			
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
			if (paused && netS) netS.pause()
			//netS.bufferTime = 0.2
		}
		
		// gets called when netStream got metadata from loading video
		public function onMetaData(info:Object):void {
		
			if (gotMetaData) return
				
			gotMetaData = true
			
			// set values from event
			fps = info.framerate ? info.framerate : info.videoframerate,
			width = info.width
			height = info.height
			
			
			duration = info.duration
			
			fireEvent(StreamEvent.INFO,fps)
			
        }
        
        // pause playback
		override public function pause():Boolean {
			if (paused) return false
			paused = true;
			if (!buffering && !stopped) fireEvent(StreamEvent.PAUSE,time)
			netS.pause()
			return true
		}
		
		// resume playback
		override public function resume():Boolean {
			if (started && (buffering || bytesLoaded == 0 || position == 1 && playStarted)) return false
			
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
			if (buffering) return false
			if (!started) {
				// if stream is not started, do it now
				streamStart()
			}
			
			if (netStweakBuffer && netS.bufferLength >= 0.5) netS.bufferTime = netS.bufferLength
			
			netS.resume()
			
			paused=false
			return true
		}
		
		
		// seek stream
		override public function seek(pos:Number,end:Boolean = true):Number {
			if (!gotFull) {
				return 0
			}
			if (loaded < 1) {
				// limit position to loaded data only
				pos = Math.min(pos,loaded)
			}
			seekPos = duration*pos
			
			seekedForward = seekPos > time
			
			netS.seek(seekPos)
			fireEvent(StreamEvent.SEEK,uint(pos*1000+.5)/1000)
			
			if (pos > 0) stopped = false
			
			return pos
		}
		
		// called when buffer needs to be filled
		public function fillBuffer(e:Event=null):void {
			if (loaded == 1) return
			buffering = true;
			pause()
			//netS.bufferTime = 2
			if (netStweakBuffer && netS.bufferTime < 2) {
				netS.bufferTime = 2
			}
			bufferTimeStart = getTimer()
			
		}
		
		/*
			here we are, calculate buffer size using
			
			- at least 2s of bufferLength
			- estimated download time based on download speed
			- bufferTimeMax (seconds) as upper limit 
	
			a normalizer is also used so returned value
			- falls in the 0-1 range
			- never decrease
			
		*/ 
		public function get bufferLoaded():Number {
			
			// self explanatory variables
			var downloadSpeed:Number = 1000*bytesLoaded/(getTimer()-startTime)
			var requiredTime:Number = (bytesTotal-bytesLoaded)/downloadSpeed
			var timeLeft:Number = duration-time
			
			var bufferTimeElapsed:Number = Math.min((getTimer()-bufferTimeStart)/1000/bufferTimeMax,1);
			
			// calculate buffer loaded (0-1 range)
			var bL:Number = Math.min(Math.min(netS.bufferLength/2,1),Math.max(Math.min((timeLeft*0.9)/requiredTime,1),bufferTimeElapsed))
			
			// if movies is completely loaded or bL == 1
			if (loaded == 1 || uint(bL*100+0.5)/100 == 1) {
				// reset normalizer
       			bufferNormalizer = 1
				lastBufferEventValue = 0
				return 1
       		}
       			
       		// set normalizer if bL is lower then previous normalizer
    		if (bL < bufferNormalizer ) {
    			bufferNormalizer = bL
    		}
       		   			
       		// normalize buffer
    		bL = (bL - bufferNormalizer)/(1 - bufferNormalizer)
       		
    		if (bL > lastBufferEventValue) { 
    			lastBufferEventValue=bL
    		} else {
    			// bL is lower then previous value
    			bL = lastBufferEventValue
    		}
			
			return uint(bL*100+0.5)/100
		}
		
		// this controls how stream is loading
		protected function controlHandler(e:Event):void {
		
			if (bytesLoaded > 0) {
				// if got bytes, fire STREAMING
				if (!lastEventValue[StreamEvent.STREAMING]) fireEvent(StreamEvent.STREAMING,loaded,true)
				// fire PROGRESS event
        		fireEvent(StreamEvent.PROGRESS,loaded,true)
			}
		
			
			// fire POSITION event if not buffering
        	if (gotMetaData && !fixUnbufferedSeekTimer.running && !buffering) {
        		fireEvent(StreamEvent.POSITION,position,true)
        	}
        	
        	// this may cause glitchy playback with some videos, disabling for now
        	if (!gotFull && !paused && startTime > 0 && lastPlayedTime == time) {
        		// this will force resume to make playback starts ASAP
        		if (netS.bufferLength >= 0.5) _resume()
        		//_resume()
			}
			
			if (seekedForward && gotFull && !buffering && !paused && loaded<1 && startTime > 0 && lastPlayedTime == time && !fixUnbufferedSeekTimer.running && !bufferTimer.running ) {
				// EEEK! playback stopped when not supposed to....
				// most common cause, user seeked forward to unbuffered data
				// so, fix the thing
				seekPos = lastPlayedTime > seekPos ?  lastPlayedTime : seekPos				
				fixUnbufferedSeekTimer.start()
			}
			
        	if (buffering) {
        			
        		var bL:Number = bufferLoaded
        		// fire BUFFERING event
        		fireEvent(StreamEvent.BUFFERING,bL,true)
        		
        		if (bL == 1) {
        			buffering = false
        			resume()
        		}
        	}
        	
        	if (!fixUnbufferedSeekTimer.running && !buffering) {
        		// update last played time
        		lastPlayedTime = time
        	}
        	
        }
		
		// this will seek back stream
		protected function seekBack(t:Number):void {
			seekPos = Math.max(seekPos-t,0)
			netS.seek(seekPos)
		}
		
		// this is used to unlock a freezed stream
		protected function fixUnbufferedSeek(e:Event):void {
			if (loaded == 1) {
				fixUnbufferedSeekTimer.reset()
			} else {
				seekBack(0.5)
			}
		}
		
		// set volume
		override public function volume(vol:Number):void {
			if (!netInited || !netS) return
			var sT:SoundTransform = netS.soundTransform
			sT.volume = vol
			netS.soundTransform = sT
			super.volume(vol)
		}
		
		// netStream events handler
		protected function netHandler(e:*):void {
			// ignore
			if (e is flash.events.AsyncErrorEvent) return
		
			switch (e.info.code) {			
				case "NetStream.Play.Start":
					// playback is started
					startTime = getTimer()
					if (!paused && !playStarted) {
						fireEvent(StreamEvent.PLAY,startTime)
						playStarted = true
					}
				break;
				case "NetStream.Buffer.Flush":
				break;
				case "NetStream.Buffer.Empty":
					if (netS.bufferLength < 2) {
						// buffer is empty, if it does not fill quick, start buffering procedure
						bufferTimer.reset()
						bufferTimer.start()
					}
				break;
				case "NetStream.Buffer.Full":
					// yeah, buffer is filled again
					gotFull = true
					// reset the "fill buffer" timer since it's not needed anymore
					bufferTimer.reset()
					if (fixUnbufferedSeekTimer.running) {
						fixUnbufferedSeekTimer.reset()
						seekedForward = false
					}
				break;
				case "NetStream.Play.Stop":
					if (loaded < 1)	{
						// EEEK! we got a STOP but movie is not fully loaded ....
						// most common cause, user seeked forward to unbuffered data
						// fix the thing
						seekBack(1)
					} else {
						stop();
					}
				break;
				case "NetStream.Seek.Notify":
				break;
				case "NetStream.Play.StreamNotFound":
					fireEvent(StreamEvent.NOT_FOUND,getTimer())
				break
			}
		}
		
		override public function destroy():void {
			super.destroy()
			netC.close()
			netS = undefined
		}
			
	}
}
/* commentsOK */