/*

	Implements a media thumbnails scroller using tweens, enlight and reflection
	Common functions are defined in thumbs.as
	
*/
package bitfade.media.preview {	
	
	import flash.display.*;
	import flash.events.*
	import flash.utils.*
	import flash.geom.Rectangle
	
	import bitfade.easing.*
	
	import bitfade.utils.*
	import bitfade.effects.RefPlane
	
	import bitfade.ui.frames.Shape
	import bitfade.ui.backgrounds.engines.Reflection
	import bitfade.ui.thumbs.Thumb
	
	public class Reflection extends bitfade.media.preview.Thumbs  {
		
		// tweens database
		protected var twDB:Dictionary
		
		// default tween function
		protected var defTwOptions:Object = {ease:Quad.Out}
		
		// reflection plane
		protected var rPlane: bitfade.effects.RefPlane
		
		protected var invalidated:Boolean = false
		protected var delayedUpdate:RunNode
		
		protected var activeTW:uint = 0
		
		public function Reflection(...args) {
			super()
			
			defaults.reflection = {
				enabled: true,
				falloff: 38,
				alpha: 100,
				offset: 40
			}
			
			
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		override protected function initDisplay(...args):void {
		
			// create tween DB
			twDB = new Dictionary(true)
			
			// run tick() every frame
			Run.every(Run.FRAME,tick)
 			
 			// call parent
 			super.initDisplay()
			
			if (conf.reflection.enabled) {
				// create reflection plane
				rPlane = new RefPlane({target:container,width:w,height:th,alpha:conf.reflection.alpha,falloff:conf.reflection.falloff,autoUpdate:false})
				rPlane.init()
				rPlane.y = container.y+th+conf.reflection.offset
				addChildAt(rPlane,getChildIndex(container)+1)
			
					// add listeners
				bitfade.utils.Events.add(this,[
					Event.RENDER
				],render)
			
			}
			
		}
		
		// set tween properties
		protected function setTw(thumb:bitfade.ui.thumbs.Thumb,values:Object,onComplete:Function = undefined) {
			var tween:bitfade.utils.Tw = bitfade.utils.Tw.unique(twDB,thumb, .7, values, defTwOptions);
			tween.onComplete = onComplete
		}
		
		// position a thumbnail
		override protected function showThumb(thumb:bitfade.ui.thumbs.Thumb,x:int,y: int):void {
			setTw(thumb,{y: y,x:x,alpha:1})
		}
		
		// remove a thumbnail
		override protected function removeThumb(head:Boolean = false):void {
			var thumb:bitfade.ui.thumbs.Thumb = head ? list.shift() : list.pop() 
			if (thumb) {
				container.setChildIndex(thumb,0)
				var extraMargin:int = Math.max(0,int(conf.thumbs.horizMargin-tw))
				setTw(thumb,{y: bottom,x: head ? extraMargin : w-tw-extraMargin,alpha:0},repoolTW)
			}
		
		}
		
		// repool a thumbnails
		protected function repoolTW(t:bitfade.utils.Tw) {
			var target:* = t.target
			repool(target)
		}
		
		// render reflection plane
		protected function render(e:Event) {
			rPlane.update()
			invalidated = false
		}
		
		public function tick():void {
			
			var count:uint = 0
			activeTW = 0
			
			// count active tweens
			for (var i in twDB) {
				count++
				if (!twDB[i].paused) activeTW++
			}
			
			if (activeTW > 0) {
				// the more tweens are active, the more we augment speed
				var timeScale:Number = Math.max(1,activeTW/(max+1)) 
			
				// set new timeScale
				for (i in twDB) {
					bitfade.utils.Tw(twDB[i]).timeScale = timeScale
					
				}
				
				// reflection needs update
				invalidate()
			} else if (conf.reflection.enabled) {
				
				// see if we have thumbs updating
				var j:uint = list.length
				while (j--) {
					if (list[j].updating) {
						// reflection needs update
						invalidate()
						break;
					}
				}
			
			}
		}
		
		protected function invalidate() {
			if (!invalidated && conf.reflection.enabled) {
				// invalidate stage so a RENDER event will be fired
				stage.invalidate()
				invalidated = true
			}
		}
		
		override public function destroy():void {
			// clean stuff
			Run.reset(tick)
			super.destroy()
		}
		
		override protected function localResize():void {
			if (rPlane) {
				// resize reflection plane
				rPlane.resize(w,th)
				rPlane.y = container.y+th+conf.reflection.offset
			}
		}
	}
	
}
/* commentsOK */