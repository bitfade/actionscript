/*

	This class is used display a video stream

*/
package bitfade.media.visuals {
	
	import flash.display.*
	import flash.geom.*
	import flash.media.Video
	import flash.events.Event
	
	import bitfade.core.*
	
	import bitfade.media.visuals.Visual
	import bitfade.media.streams.*
	import bitfade.utils.*
	
	
	public class Video extends bitfade.media.visuals.Visual {
		
		protected var vid:flash.media.Video
		
		// current video size
		protected var vw:uint = 0
		protected var vh:uint = 0
		
		// constructor
		public function Video(w:uint=0,h:uint=0) {
			super()
			vid = new flash.media.Video()
			addChild(vid)
			resize(w,h)
		}
		
		// link the video visualizer to a video stream 
		override public function link(s:*):void {
			visible = false
			vid.attachNetStream(s.netStreamObject)
			// call init when we have video metadata
			Events.add(s,StreamEvent.INFO,init)
		}
		
		// gets called when we have video metadata
		protected function init(e:StreamEvent):void {
			vw = e.target.width
			vh = e.target.height
			scale()
			visible = true
		}
		
		// scale the video
		override protected function scale():void {
		
			if (!vid || (vw == 0 && vh == 0)) return
			// get the scaler
			var scaler:Object = Geom.getScaler(scaleMode,"center","center",maxW,maxH,vw,vh)
				
			// ADDED INT/UINT
				
			// set new size and offset
			vid.x = int(scaler.offset.w)
			vid.y = int(scaler.offset.h)
			
			vid.width = uint(scaler.ratio*vw)
			vid.height = uint(scaler.ratio*vh)
			
			vid.smoothing = scaler.ratio == 1 ? false : true
		}
				
	}
}
/* commentsOK */