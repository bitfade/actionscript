/*

	Video background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.utils.*
	
	import bitfade.media.players.*
	import bitfade.media.visuals.*
	import bitfade.media.streams.*
	import bitfade.media.visuals.*
			
	
	import bitfade.utils.*
	import bitfade.effects.*
	import bitfade.transitions.*
	import bitfade.easing.*
	
	public class Video extends Background {
	
		protected var onReadyCallBack:Function
		protected var transitionLoop:RunNode
		protected var started:uint;
		protected var buffering:Boolean = true
		protected var resource:* 
		protected var previewVideo: bitfade.media.players.SimpleVideo
		
		protected var bMap:Bitmap
		protected var bData:BitmapData
		
		public function Video(...args) {
			configure.apply(null,args)
		}
		
		// include needed screan class
		protected function includeStreamClass():void {
			bitfade.media.streams.Video.addClass()
			var videoV:bitfade.media.visuals.Video
		}
		
		public function get playbackReady():Boolean {
			return !buffering
		}
		
		override protected function init():void {
			super.init()
			
			if (onReadyCallBack != null) onReadyCallBack()
		}
		
		override public function onReady(cb:Function) {
			onReadyCallBack = cb
		}
		
		override public function start():void {
			bData = Bdata.create(w,h)
			bMap = new Bitmap(bData)
			
			addChild(bMap)
		
			previewVideo = new bitfade.media.players.SimpleVideo(w,h,true,false)
			FastTw.tw(previewVideo).params(.5,bitfade.easing.Linear.In)
			addChild(previewVideo)
			transitionLoop = Run.every(Run.FRAME,computeTransition)
		}
		
		public function currentPlayed(url:String) {
			return resource == url
		}
		
		// load and display a new video stream 
		override public function show(content:*,opts:Object = null):void {
			if (resource != content.resource) {
				resource = content.resource
				previewVideo.bind(content)
				previewVideo.alpha = 0
				previewVideo.visible = true
				FastTw.tw(previewVideo).alpha = 1
			}
		}
		
		// freeze current displayed video
		public function freeze():void {
			Snapshot.take(previewVideo,bMap,w,h)
			previewVideo.close()
			previewVideo.visible = false
		}
		
		protected function computeTransition() {
			
		}
		
		public static function get resourceType():String {
			return "video"
		}
		
		// clean up
		override public function destroy():void {
			Run.reset(transitionLoop)
			previewVideo.destroy()
			previewVideo = undefined
			super.destroy()
		}
		
		
	}

}
/* commentsOK */