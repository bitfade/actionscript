/*

	Implements a media thumbnails playlist with video preview
	
*/
package bitfade.media.preview.playlist {	
	
	import bitfade.media.preview.playlist.Reflection
	import bitfade.media.players.SimpleVideo
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	import bitfade.utils.*
	import bitfade.ui.thumbs.Thumb
	
	public class Video extends bitfade.media.preview.playlist.Reflection  {
		
		// video preview component
		protected var previewVideo: bitfade.media.players.SimpleVideo
		protected var previewVolume:Number = 0.5
		protected var previewActive:Boolean = false;
		protected var selectedThumb:bitfade.ui.thumbs.Thumb
		
		protected var delayedPreview:RunNode
		
		public function Video(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		override protected function overrideDefaults():void {
			
			defaults.video = {
				type: "Video"
			}
			
			super.overrideDefaults()
		}
		
		public function volume(vol:Number) {
			previewVolume = vol
			if (previewVideo) previewVideo.volume(vol)
		}
		
		override protected function initDisplay(...args):void {
			// parent init
			super.initDisplay.apply(null,args)
			
			// create the preview component
			var margins:Object = Geom.splitProps(conf.thumbs.margins,true)
			
			previewVideo = new bitfade.media.players.SimpleVideo(tw-2*margins.w,th-2*margins.h)
			previewVideo.x = margins.w
			previewVideo.y = margins.h
			
			previewVideo.defaultType = conf.video.type
			
			previewVideo.visible = false
			
			// check this out
			previewVideo.mouseEnabled = false
			previewVideo.mouseChildren = false
			
			addChild(previewVideo)
			
		}
		
		
		// gets called on enterFrame
		override public function tick():void {
			super.tick()
			if (previewActive && previewVideo.isDrawable) invalidate()
		}
		
		// render reflection plane
		override protected function render(e:Event) {
			if (previewActive && !previewVideo.isDrawable) {
				selectedThumb.removeChild(previewVideo)
				super.render(e)
				selectedThumb.addChildAt(previewVideo,3)
				//container.
			} else {
				super.render(e)
			}
			
			
		}
		
		// show video preview
		protected function showPreview() {
			var id:uint = parseInt(selectedThumb.name)
			
			// if no resource, do nothing
			if (!conf.item[id].preview) return
			// load the movie
			previewVideo.volume(previewVolume)
			previewVideo.load(conf.item[id].preview)
			
			selectedThumb.addChildAt(previewVideo,3)
			// show the component
			previewVideo.visible = true
			
			
			previewActive = true
			
		}
		
		// hide video preview
		protected function hidePreview() {
			Run.reset(delayedPreview)
			
			
			if (previewActive) {
				
				if (previewVideo.parent) {
					previewVideo.parent.removeChild(previewVideo)
				}
				previewActive = false
				previewVideo.visible = false
								
				previewVideo.close()
				
			}
		}
		
		override protected function setTw(thumb:bitfade.ui.thumbs.Thumb,values:Object,onComplete:Function = undefined) {
			if (previewActive && thumb == selectedThumb) {
				hidePreview()
			} 
			super.setTw(thumb,values,onComplete)
		}
		
		override protected function evHandler(e:*):void {
			super.evHandler(e)
			
			if (e.target is bitfade.ui.thumbs.Thumb) {
				switch (e.type) {
					case MouseEvent.MOUSE_OVER:
					case MouseEvent.MOUSE_OUT:
						if (e.type == MouseEvent.MOUSE_OVER) {
							// mouse over thumb, show preview after 0.5s
							selectedThumb = e.target
							delayedPreview = Run.after(0.5,showPreview,delayedPreview)
						} else {
							// mouse out, hide preview
							hidePreview()
						}
					break;
					case MouseEvent.MOUSE_DOWN:
						// click, hide preview
						hidePreview()
						e.target.over(false)
					break;
				}
			}
		}
		
		// hide playlist
		override public function hide() {
			super.hide()
			hidePreview()
		}
		
		// show playlist
		override public function show(sw:Boolean = true) {
			if (locked || (visible == sw) ) return
			if (sw) {
				if (conf.item[startIndex].caption) description(conf.item[startIndex].caption[0].content)
			}
			super.show(sw)
		}
		
		override protected function loadResource(thumb:bitfade.ui.thumbs.Thumb,item:Object) {
			thumb.load(item.thumb)
		}
		
		
	}
	
}
/* commentsOK */