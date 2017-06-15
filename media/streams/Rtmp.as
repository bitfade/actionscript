/*

	This class handles rtmp streams

*/
package bitfade.media.streams {
	
	import flash.display.*
	import flash.media.*
	import flash.net.*
	import flash.events.*
	import flash.utils.*
	
	import bitfade.utils.Events
	
	public class Rtmp extends bitfade.media.streams.Video {
	
		protected var connected:Boolean = false
		protected var netStop:Boolean = false
		protected var startPaused:Boolean 
		protected var startBuffering:Boolean
		
		protected var lastSeekTime:int
		protected var server:String
		protected var clip:String
	
		// constructor
		public function Rtmp() {
			addClass()
			super()
		}
		
		public static function addClass():void {
			Stream.addStreamType("Rtmp");
		}
		
		override public function get type():String {
			return "Rtmp"
		}
		
		
		// init flash.net stuff
		override protected function initNet():void {
		
			// if inited, do nothing
			if (netInited) return
			
			netInited = true
			netStweakBuffer = false
		
			// create NetConnection and NetStream objects
			netC = new NetConnection();
			netC.client = this
			
			bitfade.utils.Events.add(netC,NetStatusEvent.NET_STATUS,netHandler,this)
			bitfade.utils.Events.add(netC,AsyncErrorEvent.ASYNC_ERROR,netHandler,this)
			bitfade.utils.Events.add(netC,SecurityErrorEvent.SECURITY_ERROR,netHandler,this)
			
			
			netC.connect(server);
			fireEvent(StreamEvent.CONNECT,getTimer())
			
		}
		
		// return if stream is ready to play
		override public function get ready():Boolean {
			return connected
		}
		
		override public function get bytesLoaded():uint {
			return netInited ? 1 : 0
		}
		
		// this controls how stream is loading
		override protected function controlHandler(e:Event):void {
		
			//if (netS.bufferLength > 0) trace(netS.bufferTime,netS.bufferLength)
		
			// fire POSITION event if not buffering
        	if (gotMetaData && !buffering) {
        		fireEvent(StreamEvent.POSITION,position,true)
        	}
        	
        	if (buffering) {        			
        		var bL:Number = Math.min(1,int(100*netS.bufferLength/netS.bufferTime)/100)
        		
        		fireEvent(StreamEvent.BUFFERING,bL,true)
        	}
        	
        	if (!buffering) {
        		// update last played time
        		lastPlayedTime = time
        	}
        	
        }
		
		
		// load a movie
		override public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {
			resource = Stream.getResourceFrom(url);
			
			var tokens:Array = resource.split("/")
			
			clip = tokens.pop()
			server = tokens.join("/")
			
			initNet()
			reset()
			
			playedStreams++
			
			this.startPaused = startPaused
			this.startBuffering = startBuffering
			
		}
		
		// gets called when we need to start loading the movie
		override protected function streamStart():void {
			started = true
			netS.play(clip)
		}
		
		// seek stream
		override public function seek(pos:Number,end:Boolean = true):Number {
			
			if (!gotFull) {
				return 0
			}
			
			if (getTimer() - lastSeekTime < 500) {
				return seekPos/duration
			}
			lastSeekTime=getTimer();
				
			seekPos = duration*pos
			netS.seek(seekPos)
			resume()
			fireEvent(StreamEvent.SEEK,uint(pos*1000+.5)/1000)
			
			if (pos > 0) stopped = false
			
			return pos
		}
		
		protected function netConnectionReady():void {
			createNetS();
			connected = true
			
			fireEvent(StreamEvent.READY,getTimer())
			fireEvent(StreamEvent.STREAMING,getTimer())		
			//streamStart()
					
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
			if (paused) netS.pause()

		}
		
		// netStream events handler
		override protected function netHandler(e:*):void {
		
			if (!(e is flash.events.NetStatusEvent)) return
			
			switch (e.info.code) {
				case "NetConnection.Connect.Rejected":
					fireEvent(StreamEvent.NOT_FOUND,getTimer())
				break
				case "NetConnection.Connect.Success":
					netConnectionReady()
				break;
				case "NetStream.Play.Start":
					if (netS.bufferLength < 0.1) {
        				buffering = true
        			}
    				super.netHandler(e)
				break;
				
				case "NetStream.Buffer.Empty":
					if (!stopped && netS.bufferLength < 2) {
						buffering = true
					}
				break;
				case "NetStream.Buffer.Full":
					// yeah, buffer is filled again
					gotFull = true
					if (buffering) {
						fireEvent(StreamEvent.BUFFERING,1,true)
						buffering = false
						fireEvent(StreamEvent.RESUME,1)
					}
				break;
				case "NetStream.Play.Stop":
				break;
				default:
					super.netHandler(e)
			}
		}
		
		public function onPlayStatus(info:Object):void {
			switch (info.code) {
				case "NetStream.Play.Complete":
					stop()
				break;
			}
		}
		
		public function onBWDone(...args):void {
		
		}
		
		
		// reset current stream, clean stuff and reinitializes some values
		override protected function reset():void {
			connected = false
			netStop = false
			super.reset()
		}
			
	}
}
/* commentsOK */