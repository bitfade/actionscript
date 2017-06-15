/*

	This class defines stream events

*/

package bitfade.media.streams {	
	
	import flash.events.Event;
	
		public class StreamEvent extends Event{
		
			public static const INIT:String = "init";
			public static const INFO:String = "info";
			public static const READY:String = "ready";
			public static const START_POS:String = "start_pos";
			public static const CONNECT:String = "connect";
			public static const STREAMING:String = "streaming";
			
		
			public static const PLAY:String = "play";
			public static const PAUSE:String = "pause";
			public static const RESUME:String = "resume";
			public static const SEEK:String = "seek";
			public static const STOP:String = "stop";
			public static const BUFFERING:String = "buffering";
			
			public static const PROGRESS:String = "progress";
			public static const POSITION:String = "position";
			public static const CLOSE:String = "close";
			public static const NOT_FOUND:String = "not_found";
			public static const NET_ERROR:String = "net_error";
			
			public static const GROUP_PROGRESS:Array = [PROGRESS,POSITION,START_POS];
			public static const GROUP_PLAYBACK:Array = [INIT,READY,INFO,CONNECT,STREAMING,BUFFERING,PLAY,PAUSE,RESUME,SEEK,STOP,CLOSE,NOT_FOUND,NET_ERROR];
			
			public var value:Number;
			
			public function StreamEvent(type:String = STOP,v:Number = 0) {
				super(type,false,false);
				value = v;		
			}
			
			override public function clone():Event	{
				return new StreamEvent(type,value);
			}

	}
	
}
/* commentsOK */


