/*

	Accordion Layout

*/
package bitfade.ui.accordion {
	
	import bitfade.ui.accordion.*
	import bitfade.utils.*
	import bitfade.easing.*
	
	import flash.utils.*
	import flash.events.*
	import flash.geom.*
	
	public class AccordionLayout extends AccordionSlide {
	
		public var slides:Array = []
		protected var layoutUpdateStarted:uint
		protected var invalidated:Boolean = false
		protected var activeSlide:AccordionSlide
		
		public static var useStageInvalidate:Boolean = true
		
		public function AccordionLayout(...args) {
			super()
			if (args[0]) init.apply(null,args)
		}
		
		protected function createSlide(sw:uint,sh:uint,slideConf:Object):AccordionSlide {
		
			var ns:AccordionSlide
		
			if ((slideConf.layout == 0 || slideConf.layout == 1) || !slideConf.layout) {
				slideConf.layout = layout
				ns = new AccordionSlide(sw,sh,slideConf)
			} else {
				slideConf.child = true
				ns = new AccordionManager(sw,sh,slideConf)
			}
			return ns
		}
		
		override protected function build():void {
			resize(w,h)
			if (conf.child) return
			if (useStageInvalidate) Events.add(this,[Event.RENDER],render)
			Run.every(Run.FRAME,layoutHandler)
			Events.add(this,[MouseEvent.MOUSE_OVER,MouseEvent.MOUSE_OUT,MouseEvent.MOUSE_WHEEL],eventHandler)
			
		}
		
		
		public function addSlide(slideConf:Object,atStart:Boolean=false):AccordionSlide {
			var sn:uint = slides.length 
			var sl:AccordionSlide
			
			size[0] = w
			size[1] = h
			
			size[layout] = slideConf.closedSize
			
			offs[0] = 0
			offs[1] = 0
			
			sl = createSlide(size[0],size[1],slideConf)
			
			sl.x = offs[0]
			sl.y = offs[1]
			
			/*
			if (sn > 0) {
				sl[axis[layout]]=(slides[sn-1][axis[layout]]+slides[sn-1][prop[layout]])
			}
			*/
			
			if (atStart) {
				slides.unshift(sl)
			} else {
				if (sn > 0) {
					sl[axis[layout]]=(slides[sn-1][axis[layout]]+slides[sn-1][prop[layout]])
				}
				slides.push(sl)
			}
			
			content.addChild(sl)
			sl.saveState()
			sl.layoutManager = this
			return sl;
		} 
		
		override public function saveState():void {
			super.saveState()
			
			var sn:uint = slides.length 
			for (var i:uint = 0;i<sn;i++) {
				slides[i].saveState()
			}
			
		}
		
		override protected function contentResize() {
			var r:Rectangle = content.scrollRect
			r.top = 0
			r.left = 0
			r.width = w
			r.height = h
			content.scrollRect = r
		}
		
		public function distribute():void {
		
		
			var sl:AccordionSlide
			var sn:uint = slides.length
			var activeSize:int = 0
			var i:uint
			var start:int = 0
			var end:int = 0;
			var right:uint = sn;
			var slideSizeRight:int = 0
			var slideSize:Number = 0;
			
			
			size[0] = w
			size[1] = h
			
			slideSize = size[layout]
			
			if (sn > 1) {
				if (activeSlide) {
				
					activeSize = 150+(activeSlide.id % 2)*400
					
					// check the maximum here
					activeSize = (size[layout]/sn)*3
					
					
					
					activeSize = size[layout]-int((size[layout]-activeSize)/(sn-1))*(sn-1)
					
					for (i = 0; i<sn; i++) {
						sl = slides[i]
						if (sl == activeSlide) break;
						start += sl[prop[layout]]
					}
					
					end = start+activeSlide[prop[layout]]				
					slideSize = (slideSize-activeSize)/(sn-1)
					
					if (slideSize*i > start)  {
						right = i
						slideSize = (start)/right
						slideSizeRight = (size[layout]-(start+activeSize))/(sn-1-right)
					} else if (slideSize*i+activeSize < end)  {
						right = i
						slideSize = (end-activeSize)/right
						slideSizeRight = (size[layout]-end)/(sn-1-right)
					}
					
					size[layout] = slideSize 
					
				} else {
					size[layout] = size[layout]/sn
				
				}
			}
			
			for (i = 0; i<sn; i++) {
				sl = slides[i]
				//FastTw.tw(sl.content).alpha = activeSlide ? 1:0
				
				if (i == (right+1)) {
					size[layout] = slideSizeRight
				}
				
				
				if (sl == activeSlide) {
					sl.to[prop[layout]] = activeSize
				} else {
					sl.to.width = size[0]
					sl.to.height = size[1]
				}
				
			}
			
			layoutUpdateStarted = getTimer()
			
		}
		
		override public function resize(nw:uint = 0,nh:uint = 0):void {
			super.resize(nw,nh)
			
			size[0] = w
			size[1] = h
						
			distribute()
			
		}
		
		override protected function backgroundResize() {
		}
		
		
		public function arrangeSlides(ratio:Number):void {
			var sl:AccordionSlide
			var sn:uint = slides.length 
			if (sn == 0) return
			var half:uint = activeSlide ? activeSlide.id : slides[sn-1].id
			var i:uint = 0
			var dir:uint = 0
			var incr:int = 1
			var last:Array = [0,layout ? h : w]
			var index:Array = [0,sn-1]
			var error:Number = 0
			var slideSize:Number = 0
			var slideProp:String = prop[layout]
			
			var loop:Boolean = true
			
			while (loop) {
				sl = slides[i]
				
				if (sl.id == half) {
					if (dir == 0) {
						// invert direction
						dir = 1
						i = sn-1
						incr = -1
						continue;
					} else {
						slideSize = last[1]-last[0]
						loop = false
					}
				} else {
					slideSize = sl.from[slideProp]+(sl.to[slideProp]-sl.from[slideProp])*ratio
					error += (slideSize - uint(slideSize))
					slideSize += uint(error)
					error = error % 1	
				}
				
				size[layout] = slideSize = Math.max(0,int(slideSize))
				
				sl.resize(size[0],size[1])
				sl[axis[layout]] = last[dir]-dir*slideSize
				last[dir] += incr*slideSize
				
				if (sl is AccordionManager) AccordionManager(sl).arrangeSlides(ratio);
				i += incr
			}
			
			if (ratio == 1) {
				saveState()
			}

		}
		
		protected function layoutHandler():void {
			if (layoutUpdateStarted == 0 || invalidated) return
			if (useStageInvalidate) {
				stage.invalidate()
				invalidated = true
			} else {
				render()
			}
		}
		
		protected function render(e:Event = null):void {
			invalidated = false
			if (layoutUpdateStarted != 0) {
				var duration:Number = 0.5;
				var ratio:Number = Expo.Out(Math.min(duration,(getTimer()-layoutUpdateStarted)/1000), 0, 1, duration)
				
				arrangeSlides(ratio)
				
				if (ratio == 1) {
					layoutUpdateStarted = 0
				}
			}
		}
		
		protected function eventHandler(e:Event) {
			if (e.target is AccordionSlide) {
				e.target.event(e)
			}
		}
		
		public function signal(type:uint,target:AccordionSlide) {
		
			if (locked) return
		
			switch (type) {
				case AccordionSlide.ACTIVE:
				case AccordionSlide.INACTIVE:
					activeSlide = type == AccordionSlide.ACTIVE ? target : undefined
				break;				
			}
			if (layoutManager) {
				layoutManager.signal(type,this)
			} 
			
			saveState()
			distribute()
		}
		
	}
}
/* commentsOK */