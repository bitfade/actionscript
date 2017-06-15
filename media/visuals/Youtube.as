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
	import bitfade.ui.*
	
	
	public class Youtube extends bitfade.media.visuals.Visual {
		
		protected var vid:*
		
		// current video size
		protected var vw:uint = 0
		protected var vh:uint = 0
		
		// constructor
		public function Youtube(w:uint=0,h:uint=0) {
			super()
			resize(w,h)
		}
		
		// link the video visualizer to a video stream 
		override public function link(s:*):void {
		
			visible = false
			vid = s.vid
			addChild(vid)
			
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
		
			if (!vid) return
			
			vid.setSize(maxW,maxH)
						
			
		}
		
		// set zoom mode
		override public function zoom(s:String = "none"):void {
			super.zoom(s)
			scale()
		}
		
		override public function get isDrawable():Boolean {
			return false
		}
		
		override public function destroy():void {
			if (vid) removeChild(vid)
			vid = null
			super.destroy()
		}
				
	}
}
/* commentsOK */