/*

	Accordion Layout

*/
package bitfade.ui.accordion {
	
	import flash.display.*
	import flash.geom.*
	import flash.events.*
	
	import bitfade.core.*
	import bitfade.utils.*
	import bitfade.ui.*
	
	public class AccordionSlide extends bitfade.core.Resizable {
	
		public static const ACTIVE:uint = 1
		public static const INACTIVE:uint = 2
		public static const NEXT:uint = 3
		public static const PREVIOUS:uint = 4
		
		protected var conf:Object
		
		protected var defaults:Object = {
			id: 0,
			layout: "horizontal"
		}
		
		public var content:Sprite
		protected var area:Empty
		protected var layout:uint = 0
		protected var axis:Array = ["x","y"]
		protected var offs:Array = [0,0]
		protected var size:Array = [0,0]
		protected var prop:Array = ["width","height"]
		protected var bd:Shape
		
		protected var isActive:Boolean = false
		protected var background:DisplayObject
		protected var backW:uint = 0
		protected var backH:uint = 0
		
		protected static var count:uint = 0
		
		public var id:uint = 0
		
		public var layoutManager:AccordionLayout
		
		public var to:Object = {} 
		public var from:Object = {} 
		
		public var locked:Boolean = false
		
		public function AccordionSlide(...args) {
			super()
			if (args[0]) init.apply(null,args)
		}
		
		protected function init(w:uint=320,h:uint=200,conf:Object = null,...args):void {
			this.w = w
			this.h = h
			this.conf = Misc.setDefaults(conf,defaults)
			this.layout = this.conf.layout == "vertical" ? 0 : 1
			this.id = conf.id
			
			content = new Sprite()
			content.mouseEnabled = false
			//content.alpha=0
			addChild(content)
			
			area = new Empty(w,h,true)
			area.mouseEnabled = false
			addChild(area)
			
			buttonMode = true
			
			content.scrollRect = new Rectangle(1,1,w-1,h-1)
			border()
			
			build()
		}
		
		protected function border():void {
			if (!bd) {
				bd = new Shape()
				addChild(bd)
				swapChildren(bd,area)
			}
			
			
			bd.graphics.clear()
			bd.graphics.lineStyle(1,0,1,false)
			bd.graphics.moveTo(w,0)
			bd.graphics.lineTo(w,h)
			bd.graphics.lineTo(0,h)
		}
		
		protected function build():void {
			if (conf.background) {
				ResLoader.load(conf.background,backgroundLoaded)
			}
		}
		
		protected function backgroundLoaded(back:DisplayObject):void {
			if (back) {
				background = back
				
				background.alpha = 0
				backW = background.width
				backH = background.height
				
				content.addChild(back)
				backgroundResize()
				FastTw.once(back).alpha = 1
			}
		}
		
		override public function get width():Number {
			return w
		}
		
		override public function get height():Number {
			return h
		}
		
		protected function contentResize() {
			var r:Rectangle = content.scrollRect
			r.top = 1
			r.left = 1
			r.width = w-1
			r.height = h-1
			
			r.top = 0
			r.left = 0
			r.width = w
			r.height = h
			
			
			content.scrollRect = r
				
		}
		
		protected function backgroundResize() {
			
			if (!background) return
			
			var scaler:Object = Geom.getScaler("none","center","center",w,h,backW,backH)
				
			if (scaler.ratio != background.scaleX) {
				//background.cacheAsBitmap = false
				background.scaleX = background.scaleY = scaler.ratio
			} else {
				//background.cacheAsBitmap = true
			}
			//background.cacheAsBitmap = true
				
			background.x = scaler.offset.w
			background.y = scaler.offset.h
				
				
			background["smoothing"] = scaler.ratio == 1 ? false : true

		}
		
		override public function resize(nw:uint = 0,nh:uint = 0):void {
			area.resize(nw,nh)
			super.resize(nw,nh)
			border()
			contentResize()
			backgroundResize()
		}
		
		public function saveState():void {
			from.width = w
			from.height = h
		}
		
		public function set active(isActive:Boolean) {
			this.isActive = isActive
		}
		
		public function get active():Boolean {
			return isActive
		}
		
		public function set lock(l:Boolean):void {
			locked = l
			area.mouseEnabled = locked
		}
		
		public function get dynSize():Number {
			size[0] = w
			size[1] = h
			return size[layout]
		}
		
		public function event(e:MouseEvent) {
		
			if (locked) return
		
			var fireSignal:int = -1
			
			switch (e.type) {
				case MouseEvent.MOUSE_OUT:
				case MouseEvent.MOUSE_OVER:
					fireSignal = (active = (e.type == MouseEvent.MOUSE_OVER)) ? ACTIVE : INACTIVE 
				break;
				case MouseEvent.MOUSE_WHEEL:
					fireSignal = e.delta > 0 ? PREVIOUS : NEXT
				break;
			}
			
			if (layoutManager && fireSignal > 0) {
				layoutManager.signal(fireSignal,this)
			}

		}
		
		override public function destroy():void {
			layoutManager = undefined
			super.destroy()
		}
		
	}
}
/* commentsOK */