/*

	Accordion Layout Manager - extends Layout and adds configuration parsing

*/
package bitfade.ui.accordion {
	
	import flash.utils.*
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	
	import bitfade.ui.accordion.*
	import bitfade.core.*
	import bitfade.utils.*
	import bitfade.easing.*
	
	import bitfade.Debug
	
	public class AccordionManager extends AccordionLayout {
	
		protected var scrollDirection:int = 0
		protected var scrollAmount:Number = 0
		protected var scrollLast:Number = 0
		protected var scrollStarted:int = 0;
		protected var scrollLoop:RunNode
		protected var scrollLayer:Sprite
		protected var scrollQueueSize:uint = 0;
		
		
		// start - end range of displayed thumbnails
		protected var max:int = 8
		protected var startFrom:int = 0
		protected var endOn:int = 0
		protected var first:int = startFrom
		protected var last:int = startFrom-1
		protected var items:uint=0
		
		
		protected var delayedUpdate:RunNode
		
		public function AccordionManager(...args) {
			super()
			if (args[0]) init.apply(null,args)
		}
		
		override protected function init(w:uint=320,h:uint=200,conf:Object = null,...args):void {
			super.init(w,h,conf)
			content.alpha = 1
			configure()
		}
		
		override protected function border():void {
		}
		
		protected function configure():void {
			if (conf.item) {
				addValues()
				addSlidesFromConf()
			}
		}
		
		protected function addValues():void {
			var item:Array = conf.item
			var closedSize:Number
			
			size[0] = w
			size[1] = h
			
			items = item.length
			max=Math.min(items,max)
			
			endOn = startFrom + max - 1
			closedSize = size[layout]/max
			
			for (var i:uint = 0; i<items; i++) {
				item[i].id = i
				item[i].closedSize =  closedSize
			}
			
		}
		
		protected function addSlidesFromConf():void {
			var item:Array = conf.item
			
			first = 0;
						
			update()
		}
		
		override protected function build():void {
			super.build()
			scrollLayer = new Sprite()
			//scrollLayer.blendMode = "multiply"
			//scrollLayer.alpha = 0
			scrollLayer.mouseChildren = scrollLayer.mouseEnabled = false
			content.addChildAt(scrollLayer,0)
		}
		
		// get real start index
		public function get startIndex():uint {
			var idx:int = startFrom % items
			if (idx<0) idx+= items
			return idx
		}
		
		// set start index
		public function set startIndex(idx:uint) {
			startFrom = idx
			endOn = startFrom + max - 1
			first = startFrom
			last = startFrom-1
		}
		
		// update display list
		protected function update():void {
			//	having this one to work in all situations was a real *PITA*
			
			delayedUpdate = Run.reset(delayedUpdate)
			
			var i:int
			var displayed:uint = slides.length
			
			// if already have displayed thumbnails
			if (displayed > 0) {
			
				if (startFrom > first) {
					// remove thumbs from start
					removeSlides(Math.min(startFrom - first,displayed),true) 
				} 
				
				if (endOn < last) {
					// remove thumbs from end
					removeSlides(Math.min(last-endOn,slides.length))
				}
				
				// add thumbs to start
				if (first>startFrom) {
					first = Math.min(first,startFrom+max)
					
					if (slides.length == 0) {
						// no currently displayed thumbnails, add it to end
						for (i = startFrom;i<=first-1;i++) {
							addSlideIdx(i)
						}
					} else {
						// add thumbs to start
						for (i = first-1;i>=startFrom;i--) {
							addSlideIdx(i,true)
						}
					}
				}
				
			}
			
			// add thumbs to end
			if (endOn>last) {
				last = Math.max(last,endOn-max)
				for (i = last+1;i<=endOn;i++) {
					addSlideIdx(i)
				}
			}
			
			// update indexes
			first = startFrom
			last = endOn
			
			distribute()
			saveState()
			//arrangeSlides(1)
			//layoutUpdateStarted = 0
			startScroll()
		}
		
	
		protected function startScroll():void {
			if (scrollLayer.numChildren == 0) return
			
			/*
			if (scrollLayer.numChildren > 1 ) {
				trace("LOCK")
				if (activeSlide) activeSlide.layoutManager.signal(AccordionSlide.INACTIVE,activeSlide)
				lock = true
			}
			*/
			
			
			scrollAmount = scrollLast+scrollQueueSize
			if (scrollStarted > 0) {
				//scrollStarted = getTimer()
				scrollStarted = 60
			} else {
				scrollStarted = 60
				//scrollStarted = getTimer()
			}
			
			
		
		}
		
		protected function addSlideIdx(i:uint,atStart:Boolean = false):void {
			// normalize index
			i %= items
			if (i<0) i+= items
			if (scrollLayer.numChildren > 0) {
				conf.item[i].closedSize = int(scrollLayer[prop[layout]]/scrollLayer.numChildren)
			}
			addSlide(conf.item[i],atStart)
		}
		
		// delete thumbs
		protected function removeSlides(n:int,atStart:Boolean = false):void {
			if (n >= 1) {
				if (n == slides.length) atStart = false
				scrollQueueSize = 0
				while (n--) {
					removeSlide(atStart)
				}
			}
		
		}
		
		protected function scrollLayerShift(amount:int):void {
			var i:uint = scrollLayer.numChildren
			while(i--) {
				scrollLayer.getChildAt(i)[axis[layout]] += amount
			}
		}
		
		
		protected function removeSlide(atStart:Boolean = false):void {
			var sl:AccordionSlide = atStart ? slides.shift() : slides.pop()
			
			if (activeSlide == sl) {
				//activeSlide.layoutManager.signal(AccordionSlide.INACTIVE,activeSlide)
				//sl.lock = true
				//activeSlide = undefined
			}

			var lProp:String = prop[layout]
			
			scrollDirection = atStart ? +1 : -1
			scrollQueueSize += sl[lProp]
				
			sl[axis[layout]] = atStart ? scrollLayer[lProp] : 0
			if (!atStart) scrollLayerShift(sl[lProp])
			scrollLayer.addChild(sl)
			
			if (useStageInvalidate) scrollLayer[axis[layout]] = atStart ? 0 : dynSize-scrollLayer[lProp]
				
			sl.layoutManager = undefined
		}
		
		
	
		public function advance(n:int,absolute:Boolean=false):void {
			if (absolute) {
				// some math: hard to explain but it works
				var delta:int = startFrom % items
				if (delta<0) delta+= items	
				delta = n-delta
				if (delta == 0) return				
				if (Math.abs(delta) > items/2) delta += items
				startFrom += delta
			} else {
				startFrom += n
			}
			
			endOn = startFrom + max - 1
			
			if (visible) {
				
				if (scrollStarted != 0 && !delayedUpdate) {
					delayedUpdate = Run.after(0.1,update)
				} else {
					if (!delayedUpdate) update()
				}
			} else {
				startFrom = startIndex
				startIndex = startFrom
			}
		}
		
		
		override public function signal(type:uint,target:AccordionSlide) {
			
			//if (locked) return
			
			switch (type) {
				case AccordionSlide.NEXT:
				case AccordionSlide.PREVIOUS:
					//if (layoutManager) return 
					advance(type == AccordionSlide.NEXT ? +1 : -1)
					//advance(type == AccordionSlide.NEXT ? 5 : 0,true)
					//super.signal(433,target)
					return
				break;                
			}
			super.signal(type,target)
		}    
		
		protected function scrollContent(amount:int) {
			var r:Rectangle = content.scrollRect
			r[layout == 1 ? "top" : "left"] = amount
			r[prop[layout]] = dynSize+Math.abs(amount)
			content.scrollRect = r
		}
		
		protected function doScroll():void {
			
			scrollStarted -= 1
			
			var ratio:Number = (60-scrollStarted)/60
			
			ratio = Cubic.InOut(ratio, 0, 1, 1)
			ratio = Math.min(1,ratio)
			
			var amount:Number = (scrollAmount)*(1-ratio)
			
			amount = int(amount+0.5)
			scrollLast=amount
			scrollContent(-scrollDirection*amount)
				
			
			
			if (ratio == 1 || amount == 0) {
				scrollStarted = scrollAmount = scrollLast = 0
				Gc.destroy(scrollLayer,false,false)
			
			} else {
			
				var hidden:Number = int(scrollLayer[prop[layout]]-amount)
				var sl:AccordionSlide = AccordionSlide(scrollLayer.getChildAt(0))
				
				var pos:Number = sl[axis[layout]]
				var siz:Number = sl[prop[layout]]
				
				if (scrollDirection == 1) {
					if ((pos+siz)<=hidden) {
						scrollLayerShift(-siz)
						sl.destroy()
					}
				} else {
					if (pos > 0 && pos<=hidden) sl.destroy()
				}
			}
			
			scrollLayer[axis[layout]] = scrollDirection == 1 ? -scrollLayer[prop[layout]] : dynSize
			
			
		}
		
		
		
		override protected function layoutHandler():void {
			super.layoutHandler()
			if (!invalidated) {
				if (scrollStarted != 0) {
					if (useStageInvalidate) {
						stage.invalidate()
						invalidated = true
					} else {
						if (scrollStarted != 0) doScroll()
						render()
					}
				}
			}
			
			
		}
		
		override protected function render(e:Event = null):void {
			if (useStageInvalidate && scrollStarted != 0) doScroll()
			super.render(e)
			
		}
		
		
	}
}
/* commentsOK */