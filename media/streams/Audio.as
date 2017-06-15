/*

	This class is used to hold stream properties

*/
package bitfade.media.streams {
	
	import flash.media.*
	import flash.events.*
	import flash.net.URLRequest
	import flash.utils.*
	
	import bitfade.utils.*
	
	public class Audio extends bitfade.media.streams.Stream {
	
		protected var snd:flash.media.Sound
		protected var sc:SoundChannel;
		
		protected var bufferStart:uint = 0;
		
		// some timers
		protected var controlTimer:Timer
	
		public function Audio() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Audio");
		}
		
		override public function get type():String {
			return "Spectrum"
		}
		
		// init flash.net stuff
		protected function initNet():void {
		
			// if inited, do nothing
			if (netInited) return
			
			netInited = true
			
			// create the sound object
			snd = new flash.media.Sound()
			
			// add listeners
			bitfade.utils.Events.add(snd,[
				IOErrorEvent.IO_ERROR, 
				AsyncErrorEvent.ASYNC_ERROR,
				Event.ID3,
				Event.OPEN,
				Event.COMPLETE,
				ProgressEvent.PROGRESS
			], sndHandler,this)
			
			
			// set up timers
			controlTimer = new Timer(100, 0);
            controlTimer.addEventListener(TimerEvent.TIMER, controlHandler);
            controlTimer.start()
		}
		
		protected function sndHandler(e:*) {
					
			switch (e.type) {
				case ProgressEvent.PROGRESS:
				
					// if got bytes, fire STREAMING
					if (bytesLoaded > 0 && !lastEventValue[StreamEvent.STREAMING]) {
						fireEvent(StreamEvent.STREAMING,loaded,true)
					}
					
					
					// 2nd condition needed for safari bug
					if (snd.isBuffering && bytesLoaded < bytesTotal) {
						
						buffering = true
						
					} else {
					
						if (!paused && !playStarted) {
							fireEvent(StreamEvent.PLAY,getTimer())
							playStarted = true
						} else if (buffering) {
							fireEvent(StreamEvent.RESUME,time)
						}
						
						buffering = false
						bufferStart = 0
					
					}		
				case Event.COMPLETE:
					duration = (snd.bytesTotal/(snd.bytesLoaded*1000))*snd.length;
					if (e.type == Event.COMPLETE) {
						if (buffering) {
							buffering = false
							//fireEvent(StreamEvent.BUFFERING,1,false)
							//_resume()						
						}
					}
					
				break
				case Event.SOUND_COMPLETE:
					stop()
				break;
				case IOErrorEvent.IO_ERROR:
					fireEvent(StreamEvent.NOT_FOUND,getTimer())
				break;
			}
			
			
		}
		
		// return if stream is ready to play
		override public function get ready():Boolean {
			return netInited
		}
		
		override public function get bytesLoaded():uint {
			return netInited ? snd.bytesLoaded : 0
		}
		
		override public function get bytesTotal():uint {
			return netInited ? snd.bytesTotal : 1
		}
		
		override public function get time():Number {
			return netInited && sc ? (seekPos == 0 ? sc.position/1000 : seekPos) : 0
		}
		
		// helper function
		private function _play(pos:Number = 0) {
			sc = snd.play(pos)
			volume(fadeLoopRun ? 0 : lastVol)
			bitfade.utils.Events.add(sc,Event.SOUND_COMPLETE,sndHandler,this)
		}
		
		// pause playback
		override public function pause():Boolean {
			if (paused) return false
			paused = true;
			if (!stopped) fireEvent(StreamEvent.PAUSE,time)
			if (sc) sc.stop()
			return true
		}
		
		// resume playback
		override public function resume():Boolean {
			
			if (started && bytesLoaded == 0) return false
			
			if (_resume()) {
				delete lastEventValue[StreamEvent.STOP]
				if (playStarted) {
					// not first time, fire a RESUME event
					if (lastEvent != StreamEvent.RESUME) fireEvent(StreamEvent.RESUME,time)
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
			
			if (!started) {
				// if stream is not started, do it now
				streamStart()
			}
			
			_play((seekPos > 0 ? seekPos : lastPlayedTime)*1000)
			seekPos = 0
			
			paused=false
			return true
		}
		
		// seek stream
		override public function seek(pos:Number,end:Boolean = true):Number {
			if (loaded < 1) {
				// limit position to loaded data only
				pos = Math.min(pos,loaded)	
			}
			
			if (sc) sc.stop()
			
			if (paused) {
				// if paused set pos, playback will restart on next resume() call
				seekPos = duration*pos
			} else {
				// no pause, resume playback
				_play(duration*pos*1000)
			
			}
			
			fireEvent(StreamEvent.SEEK,uint(pos*1000+.5)/1000)
			
			if (pos > 0) stopped = false
			
			return pos
		}
		
		// gets called when we need to start loading the movie
		protected function streamStart():void {
			
			started = true
			snd.load(new URLRequest(ResLoader.absoluteUrl(resource)),new SoundLoaderContext(bufferTimeMax*1000, true))
			//snd.load(new URLRequest(resource),new SoundLoaderContext(bufferTimeMax*1000, true))
			
			if (!paused) {
				_play()
			}
			fireEvent(StreamEvent.CONNECT,getTimer())
		}
		
		// load a movie
		override public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {
			resource = Stream.getResourceFrom(url);
			//resource = url;
			
			initNet()
			reset()
			
			playedStreams++
			
			if (startBuffering) {
				// start movie loading now
				paused = startPaused
				streamStart()
			} else {
				// defer mp3 loading to first resume() call
				started = false
				paused = true
			}
			
		}
		
		// reset current stream, clean stuff and reinitializes some values
		override protected function reset():void {
			super.reset()
			if (sc) {
				sc.stop()
				sc = null
				try {
					snd.close()
				} catch (e:*) {}
				
			}
									
		}
		
		
		// set volume
		override public function volume(vol:Number):void {
			super.volume(vol)
			if (!(netInited && sc)) return
			var sT:SoundTransform = sc.soundTransform
			sT.volume = vol
			sc.soundTransform = sT
		}
		
		public function getChannel():SoundChannel {
			return sc
		}
		
		// this controls how stream is loading
		protected function controlHandler(e:Event):void {
			if (bytesLoaded > 0) {
				// fire PROGRESS event
        		fireEvent(StreamEvent.PROGRESS,loaded,true)
			}
			
			if (playStarted && snd.isBuffering) {
				
				var bL:Number
				
				if (bytesLoaded >= bytesTotal) {
					bL = 1
				} else {
					if (bufferStart == 0) bufferStart = bytesLoaded
				
					bL = ((duration-time)*(bytesLoaded-bufferStart)/(bytesTotal-bufferStart))/bufferTimeMax
        			bL = uint(bL*100+0.5)/100
				}
				
				fireEvent(StreamEvent.BUFFERING,bL,true)
			}
			
			fireEvent(StreamEvent.POSITION,position,true)
			
        	if (!(stopped || paused)) {
        		// update last played time
        		lastPlayedTime = time
        		
        		if (time > 0 && time >= duration) stop()
        	}
        	        	
        }
		
	}
}
/* commentsOK */