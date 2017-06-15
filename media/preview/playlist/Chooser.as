/*

	Implements a media thumbnails playlist
	
*/
package bitfade.media.preview.playlist {	
	
	import bitfade.media.preview.Reflection
	import bitfade.ui.backgrounds.engines.Caption
	import bitfade.ui.spinners.*
	import bitfade.ui.thumbs.Thumb
	import bitfade.ui.frames.*
	import bitfade.utils.*
	import bitfade.easing.*
		
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	
	public class Chooser extends bitfade.media.preview.Reflection  {
		
		protected var captionBackground:flash.display.Shape;
		protected var captionHolder:Sprite;
		
		public function Chooser(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		protected function overrideDefaults():void {
			
			bitfade.ui.thumbs.Thumb.spinnerClass = bitfade.ui.spinners.Circle
			
			defaults.caption.height = 16
			defaults.caption.margin = 0
			defaults.caption.scheme = "dark" 
			defaults.caption.show = "top"
				
			defaults.scrollBar.show = "never"
			
			defaults.thumbs.margins="1,0"
			defaults.thumbs.scale="none"
			defaults.thumbs.bottomMargin=0
			defaults.thumbs.width=90
			defaults.thumbs.height=82
			defaults.thumbs.align="bottom,center"
				
			defaults.thumbs.spacing=-10
			defaults.thumbs.frame=0
			defaults.thumbs.enlight=1
			
			defaults.style.transparent = 20
			defaults.reflection.enabled = false	
				
		}
		
		
		override public function description(msg:String = null) {
			super.description(msg)
			if (captionHolder) {
				if (conf.reflection.enabled) {
					caption.y = h - Math.max(conf.caption.height,caption.height)-2
				} else {
					captionHolder.alpha = 0
					FastTw.tw(captionHolder).alpha = 1
				}
			}
		}
		
		override protected function drawBackground() {
			if (conf.reflection.enabled) {
				super.drawBackground()
			} else {
				Snapshot.take(bitfade.ui.backgrounds.engines.Linear.create(conf.style.type,w,h),background)
			}
		}
		
		override protected function initDisplay(...args):void {
			super.initDisplay.apply(null,args)
			caption.filters = caption.realFilters = null
			
			captionHolder = new Sprite();
			
			if (!conf.reflection.enabled) {
				captionBackground = bitfade.ui.frames.Caption.create("default."+conf.style.type,conf.thumbs.width-2,16)
				captionHolder.addChild(captionBackground)
				captionHolder.getChildAt(0).alpha = 0.9
				captionHolder.getChildAt(0).blendMode = "normal"
			}
			
			captionHolder.addChild(caption)
			
			captionHolder.mouseEnabled = false;
			captionHolder.mouseChildren = false;
			
			if (conf.reflection.enabled) {
				captionHolder.y = conf.thumbs.height
				captionHolder.y = 0
			} else {
				captionHolder.y = conf.thumbs.height - conf.caption.height - 1
			}
			
			addChild(captionHolder)
			
			captionPosition()
						
		}
		
		
		protected function captionPosition() {
		
		
			if (!captionHolder || conf.reflection.enabled) return
		
			
			var t:DisplayObjectContainer = captionHolder.parent
			
			if (!(t is bitfade.ui.thumbs.Thumb)) {
				addChild(captionHolder)
				FastTw.tw(captionHolder).stop()
				captionHolder.visible = false
				return
			}
			
			captionHolder.visible = true
			var xp:int = int((conf.thumbs.width - captionHolder.width)*0.5)
				
			if (t.x + xp < 0) xp = 0
				
			if (t.x + xp + captionHolder.width + conf.thumbs.horizMargin > w) xp = w - t.x - captionHolder.width - conf.thumbs.horizMargin
			captionHolder.x = xp

						
			

		}
		
		// handle all events
		override protected function evHandler(e:*):void {
			super.evHandler(e)
			if (conf.reflection.enabled) return
			
			var id:String = e.target.name
			
			switch (e.type) {
				case MouseEvent.MOUSE_OVER:
				case MouseEvent.MOUSE_OUT:
				
					var mouseOver:Boolean = (e.type == MouseEvent.MOUSE_OVER)
					
					switch (id) {
						case "thumbs":
						case "caption":
						break
						default:
							if (e.target is bitfade.ui.thumbs.Thumb) {
								if (mouseOver && caption.text) {
									captionBackground.width = Math.max(conf.thumbs.width-2,caption.width)
									caption.x = int((captionBackground.width-caption.width) >>> 1)
									caption.y = int((captionBackground.height-caption.height) >>> 1) - 2
									e.target.addChild(captionHolder)
								} else {
									addChild(captionHolder)
								}
								captionPosition()
								
							}
						break
						
					}
					
				break
			}
		}
		
		// repool an unused thumb
		override protected function repool(t:bitfade.ui.thumbs.Thumb) {
			super.repool(t)
			if (captionHolder.parent == t) {
				addChild(captionHolder)
				captionPosition()
			}
		}
		
		override public function tick():void {
			super.tick();
			if (activeTW > 0) captionPosition()
		}
		
	}
	
}
/* commentsOK */