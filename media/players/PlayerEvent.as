/*

	This class defines player events

*/

package bitfade.media.players {	
	
	import flash.events.Event;
	
		public class PlayerEvent extends Event{
		
			public static const READY:String = "player_ready";
			public static const PLAY:String = "player_play";
			public static const PAUSE:String = "player_pause";
			public static const SEEK:String = "player_seek";
			public static const STOP:String = "player_stop";
			public static const LOOP:String = "player_loop";
			public static const FULLSCREEN:String = "player_fullscreen";
			public static const VOLUME:String = "player_volume";
			public static const ZOOM:String = "player_zoom";
			public static const CLOSE:String = "player_close";
			
			public static const GROUP_ALL:Array = [READY,PLAY,PAUSE,SEEK,STOP,LOOP,FULLSCREEN,VOLUME,ZOOM];
			
			public var value:Number;
			
			public function PlayerEvent(type:String = PLAY,v:Number = 0) {
				super(type,false,false);
				value = v;		
			}
			
			override public function clone():Event	{
				return new PlayerEvent(type,value);
			}

	}
	
}
/* commentsOK */
