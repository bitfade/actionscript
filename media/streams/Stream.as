/*

	This base class hold stream properties
	it has to be extended to implements defined (empty) methods

*/
package bitfade.media.streams {
	
	import flash.display.*
	import flash.events.*
	import flash.utils.*
	
	import bitfade.core.IDestroyable
	import bitfade.utils.*
	
	public class Stream extends EventDispatcher implements bitfade.core.IDestroyable {
	
		// size
		public var width:uint
		public var height:uint
		
		// resource url
		public var resource:String
		
		// stream properties
		public var duration:Number = 0
		public var fps:Number = 0
		
		// buffer properties
		public var buffering:Boolean = false;
		public var bufferTimeMax:uint = 5;
		
		// current requested seek position
		protected var seekPos:Number = 0
		
		// playback properties
		public var paused:Boolean = false;
		public var started:Boolean = false;
		public var stopped:Boolean = false;
		public var playStarted:Boolean = false;
		public var playedStreams:uint = 0;
		
		protected var netInited:Boolean = false
		
		// linked loaderInstance
		protected var loaderInstance:*
		protected var loaderID:uint = 0;
		protected var loaderTimer:Timer
		protected var preloadBytes:uint = 0
		protected var preloaded:Boolean = false
		
		// last stream played time
		protected var lastPlayedTime:Number = 0;
		
		// last fired event value
		protected var lastEventValue:Object = {}
		
		// last fired event
		protected var lastEvent:String
		
		protected var errorText:String
		
		protected var lastVol:Number = 0;
		protected var savedVol:Number = 0;
		
		protected var fadeFunction:Function
		protected var fadeLoopRun:RunNode
		
		protected static var availableStreamTypes:Array = [];
		
		// constructor
		public function Stream() {
			super()
		}
		
		public function get error():String {
			return errorText
		}
		
		public function get type():String {
			return "stream"
		}
		
		protected static function addStreamType(name:String):void {
			if (availableStreamTypes.indexOf(name) < 0) availableStreamTypes.push(name)
		}
		
		/*
		
			empty methods that needs to be overridden by extenders
			refer to video.as for explanation
		
		*/
		
		public function get ready():Boolean {
			return false
		}
		
		public function load(url:String,startPaused:Boolean = false,startBuffering:Boolean = true):void {}
		
		public function close():void {}
		
		public function pause():Boolean { return false }
		
		public function resume():Boolean { return false }
		
		public function play():Boolean { return resume() }
		
		// restart playback
		public function restart():void {
			playStarted = false
			stopped = false
			lastPlayedTime = 0
			seek(0)
		}
		
		public function rewind():void {
			restart()
			pause()
		}
		 // stop playback
		public function stop():void {
			stopped = true;
			lastPlayedTime = 0
			pause()
			if (!lastEventValue[StreamEvent.STOP]) fireEvent(StreamEvent.STOP,getTimer(),true)
		}
		
		public function seek(pos:Number,end:Boolean = true):Number { return 0 }
		
		public function volume(vol:Number):void {
			lastVol = vol
		}
		
		protected function reset():void {
			buffering = false
			seekPos = lastPlayedTime = 0
			playStarted = started = stopped = false
			lastEventValue = new Array()
			lastEvent = ""
			if (playedStreams > 0) fireEvent(StreamEvent.CLOSE,0)
		}
		
		public function get bytesLoaded():uint {
			return 0
		}
		
		public function get bytesTotal():uint {
			return 1
		}
		
		public function get loaded():Number {
			return bytesLoaded/bytesTotal
		}
		
		public function get time():Number {
			return 0
		}
		
		public function get position():Number{
			return uint(1000*time/duration+0.5)/1000
		}
		
		// this is used to fire events
        protected function fireEvent(type:String,value:Number = 0,filterDuplicates:Boolean = false):void {
        	// CHECK THIS
        	//if (!netInited) return
        	if (filterDuplicates) {
        		// if we have fired same event type with same value, do nothing
        		if (lastEventValue[type] == value) return
        		lastEventValue[type] = value
        	}
        	// fire event
        	lastEvent = type
       		dispatchEvent(new StreamEvent(type,value));
        }
        
        // tell player to use spinner on buffer events
        public function get useSpinner():Boolean {
        	return true
        }
        
        // tell player to inform when seeking is ended
        public function get seekNeedsEnd():Boolean {
        	return false
        }
        
        // tell player this stream will include buffer size in buffer events
        public function get hasNumbericBuffer():Boolean {
        	return true
        }
        
        public static function type(value:String):Boolean {
        	var findClass:RegExp = new RegExp('^('+availableStreamTypes.join("|").toLowerCase()+')$','i');
        	return (value.match(findClass) != null)
        }
        
        public static function quality(value:String):Boolean {
        	return (value.match(/^(default|small|medium|large|hd720|hd1080)/) != null)
        }
        
        // split a resource in its components
        public static function splitResource(defType:String,defQuality:String,resource:String):Object {
        
        	var info:Object = {}
        	
        	var tokens:Array = resource.split(/:/)
        	
        	if (type(tokens[0])) {
        		info.type = tokens[0]
        		tokens.shift()
        	} else {
        		info.type = defType
        	}
        	
        	info.type = info.type.charAt(0).toUpperCase() + info.type.toLowerCase().substring(1,info.type.length)
        	
        	if (quality(tokens[0])) {
        		info.quality = tokens[0]
        		tokens.shift()
        	} else {
        		info.quality = defQuality
        	}
        	
        	info.resource = tokens.join(":")
        	
        	return info
        	
        	
        	
        }
        
        protected function loaderCleanUp():void {
        	Events.remove(loaderTimer)
        	loaderInstance.removeEventListener(ResLoaderEvent.CUSTOM_ABORT,abortEventHandler)
        	loaderTimer.stop()
        	loaderInstance = undefined
        		
        }
        
        protected function abortEventHandler(e:ResLoaderEvent) {
        	loaderCleanUp()
        	destroy()
        }
        
        public function fade(cb:Function,out:Boolean = true) {
        	savedVol = lastVol
        	fadeFunction = cb
        	Run.reset(fadeLoopRun)
        	fadeLoopRun = Run.every(Run.FRAME,fadeLoop,10,0,true,undefined,out)
        }
        
        public function fadeDestroy():void {
        	fade(destroy)
        }
        
        public function fadePause():void {
        	fade(pause)
        }
        
        public function fadeRewind():void {
        	fade(rewind)
        }
        
        public function fadeResume():void {
        	fade(null,false)
        	resume()
        	
        }
        
        protected function fadeLoop(r:Number = 0,out:Boolean = true) {
        	volume(savedVol*(out ? (1-r) : r))
        	lastVol = savedVol
        	if (r == 1) {
        		if (fadeFunction is Function) fadeFunction()
        		fadeLoopRun = undefined
        	} 
        }
        
        protected function loaderEventHandler(e:Event) {
        	var ratio:Number
        	
        	if (bytesTotal > 1) {
        		preloadBytes = Math.min(preloadBytes,bytesTotal)
        		ratio = (bytesTotal > 1) ? Math.min(1,bytesLoaded/preloadBytes) : 0
        	} else {
        		ratio = 0
        	}
        	//trace(resource,bytesLoaded,preloadBytes,ratio)
        	loaderInstance.customLoaderProgress(loaderID,ratio)
        	if (ratio == 1) {
        		loaderInstance.customLoaderComplete(loaderID,this)
        		loaderCleanUp()
        	}
        }
        
        // preload a stream
        public function preload(id:uint,resource:String,aL:AssetLoader,preloadBytes:uint) {
        	this.preloadBytes = preloadBytes
        	preloaded = true
        	loaderID = id
        	loaderInstance = aL
        	load(getResourceFrom(resource),true,true)
        	loaderTimer = new Timer(100, 0);
        	Events.add(loaderTimer,TimerEvent.TIMER,loaderEventHandler,this)
        	Events.add(loaderInstance,ResLoaderEvent.CUSTOM_ABORT,abortEventHandler,this)
        	loaderTimer.start()
        }
        
        public static function loader(id:uint,aL:AssetLoader,preloadBytes:uint) {
        	var resource:String = aL.getResourceFromID(id)
        	var streamClass:Class = Class(getDefinitionByName(getClassFrom("video",resource)));
        	var instance:Stream = new streamClass()
        	instance.preload(id,resource,aL,preloadBytes)
        }
        
        public static function getClassFrom(defValue:String,resource:String):String { 	
        	return "bitfade.media.streams."+(splitResource(defValue,"default",resource)).type
        }
        
        public static function getQualityFrom(defQuality:String,resource:String):String { 	
        	return (splitResource("video",defQuality,resource)).quality
        }
        
        public static function getResourceFrom(resource:String):String { 
        	return (splitResource("video","default",resource)).resource
        }
        
        public function set loop(repeat:Boolean) {
        	if (repeat) {
				Events.add(this,StreamEvent.STOP,doLoop)
        	} else {
        		removeEventListener(StreamEvent.STOP,doLoop)
        	}
        }
        
        protected function doLoop(e:Event = null):void {
        	restart()
        	resume()
        }
        
        // destructor
        public function destroy():void {
        	reset()
        	Gc.destroy(this)
        }
		
	}


}
/* commentsOK */