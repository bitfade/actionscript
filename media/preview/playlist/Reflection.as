/*

	Implements a media thumbnails playlist
	
*/
package bitfade.media.preview.playlist {	
	
	import bitfade.media.preview.Reflection
	import bitfade.ui.backgrounds.engines.Caption
	import bitfade.ui.thumbs.Thumb
	import bitfade.utils.*
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	
	public class Reflection extends bitfade.media.preview.Reflection  {
		
		protected var captionBackground:Bitmap;
		
		public function Reflection(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		protected function overrideDefaults():void {		
		}
		
		override protected function localResize():void {
			super.localResize()
			// update description background
			
			Snapshot.take(bitfade.ui.backgrounds.engines.Caption.create(conf.style.type+".matte",w,conf.caption.height),captionBackground)
			caption.y = h
		}
		
		override public function description(msg:String = null) {
			super.description(msg)
			caption.y = captionBackground.y = h
		}
		
		override protected function initDisplay(...args):void {
			bottom = 40
			captionBackground = new Bitmap();
			captionBackground.alpha = (100-conf.style.transparent)/100
			
			addChild(captionBackground)
			super.initDisplay.apply(null,args)
			
		}
		
		override public function resize(nw:uint = 0,nh:uint = 0):void {
			super.resize(nw,nh-conf.caption.height)
		}
		
	}
	
}
/* commentsOK */