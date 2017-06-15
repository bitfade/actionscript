/*

	This class defines stream events

*/

package bitfade.utils{	
	
	import flash.events.Event;
	
		public class ResLoaderEvent extends Event {
		
			public static const PROGRESS:String = "progress";
			public static const CUSTOM_LOAD:String = "custom_load";
			public static const CUSTOM_ABORT:String = "custom_abort";
			
			public var gid:uint = 0
			public var ratio:Number;
			public var total:uint = 0
			public var loaded:uint = 0;
			
			
			public function ResLoaderEvent(type:String = PROGRESS,g:uint = 0,r:Number = 0,t:uint = 0,l:uint = 0) {
				super(type,false,false);
				gid = g;
				ratio = r;
				loaded = l;
				total = t;
			}
			
			override public function clone():Event	{
				return new ResLoaderEvent(type,gid,ratio,total,loaded);
			}

	}
	
}
/* commentsOK */


