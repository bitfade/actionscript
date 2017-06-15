/*

	Mini video player with no controls

*/
package bitfade.media.players {
	
	import flash.display.*
	import flash.geom.*
	import flash.utils.*
	import bitfade.core.*	
	import bitfade.ui.spinners.*
	import bitfade.media.*
	import bitfade.media.visuals.*
	import bitfade.media.streams.*
	import bitfade.utils.*
	
	public class SimpleVideo extends Sprite implements bitfade.core.IDestroyable {
	
		// player dimentions
		protected var w:uint = 0
		protected var h:uint = 0
		
		protected var vid:bitfade.media.visuals.Visual		
		// stream controller
		protected var controlStream:Stream
		
		// volume
		protected var defaultVolume:Number = 0.75
		
		// loading spinner
		protected var spinner:bitfade.ui.spinners.Circle
		
		protected var resource:String
		protected var startPaused:Boolean = false
		
		protected var topLayer:Sprite
		protected var vidLayer:Sprite
		
		public var defaultType:String = "Video"
		
		
		public function SimpleVideo(w:uint,h:uint,startPaused:Boolean = false,useSpinner:Boolean = true) {
			super()
			init(w,h,startPaused,useSpinner)
		}
		
		// init display
		protected function init(w:uint,h:uint,startPaused:Boolean = false,useSpinner:Boolean = true):void {
			this.w = w
			this.h = h
			this.startPaused = startPaused
			
			vidLayer = new Sprite()
			topLayer = new Sprite()
			
			addChild(vidLayer)
			addChild(topLayer)
			
			mouseEnabled = false
			
			if (useSpinner) {
				spinner = new bitfade.ui.spinners.Circle()
				topLayer.addChild(spinner)
			
				spinner.x = int((w-spinner.width)/2)
				spinner.y = int((h-spinner.height)/2)		
			}
			
			setVisual()
			resize()
		}
		
		// set visualizer
		protected function setVisual():void {	
			if (controlStream && controlStream.ready) {
				
				// if we have a visualizer, remove it
				if (vid) {
					vid.destroy()
				}
				// create a new one
				createVisual()
				// link it to stream and add to its holder
				vid.link(controlStream)
				
				vid.zoom("fillmax")
				
				
				vidLayer.addChild(vid)
			}
			
		}
		
		protected function getVisualClass():String {
			return "bitfade.media.visuals."+controlStream.type;
		}
		
		protected function getStreamClass():String {
			return Stream.getClassFrom(defaultType,resource);
		}
		
		// create visualizer
		protected function createVisual():void {
			var visualClass:Class = Class(getDefinitionByName(getVisualClass()));
			vid = new visualClass(w,h)
		}
		
		// resize elements
		public function resize(nw:uint = 0,nh:uint = 0):void {
			// set new size (if needed)
			if (nw > 0) w = nw
			if (nh > 0) h = nh
			
			// mask the whole thing to new dimentions
			scrollRect = new Rectangle(0,0,w,h)
			
			if (vid) {
				vid.resize(w,h)
			}
		}
		
		protected function getStreamInstance():Stream {		
			var streamClass:Class = Class(getDefinitionByName(getStreamClass()));
			return new streamClass()
			
		}
		
		// add event listeners
		protected function addEventListeners():void {
			bitfade.utils.Events.add(controlStream,StreamEvent.GROUP_PLAYBACK,streamEventHandler,this)
		}
		
		// create control stream
		protected function createStream():void {
		
			if (controlStream) controlStream.destroy()
			
			controlStream = getStreamInstance()
			
			addEventListeners()
			
		}
		
		// load a movie 
		public function load(url:String):void {
			
			resource = url
			// create the streams
			createStream()
			
			// load movie into stream
			startPaused = false
			controlStream.load(url,startPaused,true)
			
			setStreamDefaults()
						
		}
		
		protected function setStreamDefaults():void {
			controlStream.volume(defaultVolume)
			// set max buffer time
			controlStream.bufferTimeMax = 2
			
			// set visuals
			if (controlStream.ready) {
				setVisual()
			} 

		}
		
		public function bind(controlStream:Stream) {
			if (this.controlStream) this.controlStream.destroy()
			this.controlStream = controlStream
			addEventListeners()
			setStreamDefaults()
			controlStream.dispatchEvent(new StreamEvent(StreamEvent.INFO))
			resume()

		}
		
		// pause playback
		public function pause():void {
			if (controlStream && controlStream.pause()) {
				if (vid) vid.pause()
			}
		}
				
		// resume playback
		public function resume():void {
			if (controlStream && controlStream.resume()) {
				if (vid) vid.resume()
			}
		}
		
		// play is alias of resume
		public function play():void {
			resume()
		}
		
		// helper, return a value in the 0 - 1 range 
		protected function range01(v:Number):Number {
			return v > 1 ? 1 : (v < 0 ? 0 : v)
		}
		
		// seek playback
		public function seek(pos:Number):void {
			if (controlStream) {
				// to be checked
				if (!controlStream.playStarted) return resume()
				
				pos = range01(pos)
				if (pos != controlStream.position) {
					
					pos = controlStream.seek(pos)
			
					//seekBar.pos(-1,pos)
				}
			}
		}
		
		// play is alias of resume
		public function close():void {
			if (controlStream) controlStream.destroy()
			if (vid) vid.destroy()
			vid = undefined
			controlStream = undefined
		}
		
		// stop playback
		public function stop():void {
			if (controlStream) controlStream.stop();
		}
		
		// this gets called when streams ends
		protected function onStreamEnd():void {
			controlStream.restart()
			controlStream.resume()
		}
		
		public function volume(vol:Number):void {
			if (controlStream) controlStream.volume(vol)
			defaultVolume = vol
		}
		
		// stream event handler
		protected function streamEventHandler(e:StreamEvent):void {
			var msg:* = false
			dispatchEvent(e)
			
			switch (e.type) {
				case StreamEvent.INIT:
					// stream init
					if (spinner) spinner.show()
					setVisual()
				break;
				case StreamEvent.READY:
					// stream is ready
					setVisual()
				break;
				case StreamEvent.NOT_FOUND:
					// connect, show spinner
					if (spinner) spinner.hide()
				break;
				case StreamEvent.CONNECT:
				case StreamEvent.BUFFERING:
					// connect, show spinner
					if (controlStream.useSpinner && spinner) spinner.show(0.1)
				break;
				case StreamEvent.INFO:
				break;
				case StreamEvent.PLAY: // check this
				case StreamEvent.STREAMING:
				case StreamEvent.RESUME:
					// playback resume, hide spinner
					if (spinner) spinner.hide()
				break;
				case StreamEvent.STOP:
					// check for loop
					onStreamEnd()
				break;
				
			}			
		}
		
		public function get isDrawable():Boolean {
			if (!vid) return true
			return vid.isDrawable
		}
		
		// destruct player
		public function destroy():void {
			Gc.destroy(controlStream)
			controlStream = undefined
			Gc.destroy(this)
			vid = undefined
			
		}
	}
}
/* commentsOK */