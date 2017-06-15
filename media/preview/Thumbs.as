/*

	Implements a media thumbnails scroller.
	This is the base class implementing common functions.
	
	Fancy effects are defined in other classes extending this one

*/
package bitfade.media.preview {	
	
	import flash.display.*;
	import flash.events.*
	import flash.filters.*
	
	import bitfade.core.*
	import bitfade.utils.*
	import bitfade.ui.frames.Shape
	import bitfade.ui.backgrounds.engines.Reflection
	import bitfade.ui.thumbs.Thumb
	import bitfade.ui.*
	import bitfade.ui.sliders.*
	
	import bitfade.ui.text.*
	import bitfade.easing.*
	
	public class Thumbs extends Sprite implements bitfade.core.IBootable,bitfade.core.IResizable,bitfade.core.IDestroyable {
		
		// config name used for flashVars
		public var configName:String = "scroller"
		
		// defaults, no need to modify anything here
		// please refer to help files
		public var defaults:Object = {
			width: 0,
			height: 0,
			loop: true,
			visible: true,
			
			openUrl: true,

			thumbs: {
				width: 160,
				height: 120,
				scale: "fillmax",
				align: "center,center",
				frame: 3,
				enlight: 3,
				enlightMode: "default",
				margins: "9,8",
				spacing: 2,
				bottomMargin: 50,
				horizMargin: 14
			
			},
			
			caption: {
				show: "bottom",
				height: 40,
				margin: 0
				
			},
			
			scrollBar: {
				show: "top",
				showOnOver: true,
				autoHide: 1
			},
			
			style: {
				type: "dark",
				transparent: 0,
				
				text: <style><![CDATA[
					title {
						color: #FFD209;
						font-family: Sapir Sans;
						font-size: 16px;
						text-align: center;
					}
					description {
						color: #FFFFFF;
						font-family: Sapir Sans;
						font-size: 13px;
						text-align: left;
					}
					index {
						color: #FFD209;
						font-family: Sapir Sans;
						font-size: 10px;
						font-weight: bold;
						text-align: center;
					}
				]]></style>.toString()
			},
			
			external: {
				font: "resources/fonts/Sapir.swf"
			}
		}
		
		public var conf:Object = {}
		
		// background
		protected var background:Bitmap
		
		// thumbnails holder (display list)
		protected var container:Sprite
		
		// seek bar
		protected var seekControl:bitfade.ui.sliders.Index
		
		// left/right buttons
		protected var leftArea:bitfade.ui.Empty;
		protected var rightArea:bitfade.ui.Empty;
		protected var prev:flash.display.Shape
		protected var next:flash.display.Shape
		protected var prevTw:bitfade.utils.Tw
		protected var nextTw:bitfade.utils.Tw
		
		// caption text
		protected var caption:bitfade.ui.text.TextField
		
		// start - end range of displayed thumbnails
		protected var startFrom:int = 0
		protected var endOn:int = 0
		protected var first:int = startFrom
		protected var last:int = startFrom-1
		
		// thumbnails holder (data list)
		protected var list:Array
		protected var pool:Array
	
		
		// dimentions
		protected var w:uint = 0
		protected var h:uint = 0
		protected var bottom:uint = 0
		
		// thumb dimentions
		protected var tw:uint = 0
		protected var th:uint = 0
		
		// needed to compute actual number of displayed thumbnails
		protected var max:uint = 0
		protected var items:uint = 0
		protected var step:uint = 0
		protected var offs:uint = 0
		
		// to lock/unlock scrolling ('coz going too fast is bad)
		protected var scrollUnlockTimer:RunNode
		protected var scrollLock:Boolean = false
		
		// function to be called on thumbnails click
		protected var clickCallback:Function
		protected var clickCallbackValues:Boolean = false
		
		// used to show/hide the component
		protected var fadeLoop:RunNode
		protected var locked:Boolean
		
		public function Thumbs(...args) {
			super();
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// this gets called on ADDED_TO_STAGE
		public function boot(...args):void {
			Config.parse(this,init,args)
		}
		
		// init scroller
		protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			if (xmlConf) {
				// override with xml conf
				conf = Misc.setDefaults(XmlParser.toObject(xmlConf),conf)
			} else {
				// if we have no conf, try to load a default
				// this is just needed when testing component in Flash IDE
				Config.parse(this,init,["xml/config.xml"])
				return
 			}
			
			// set dimentions
			w = conf.width > 0 ? conf.width : stage.stageWidth
			h = conf.height > 0 ? conf.height : stage.stageHeight
			bottom = conf.thumbs.bottomMargin
			
			tw = conf.thumbs.width
			th = conf.thumbs.height
			
			
			if (!conf.item) conf.item = []
			
			// number of items
			items = conf.item.length
			name = configName
			
			list = new Array()
			pool = []
			
			conf.thumbs.type = conf.style.type
			
			addIds()
			
			visible = conf.visible
			
			// load external fonts, if needed
			Config.loadExternalResources(conf.external,initDisplay)
		}
		
		protected function addIds() {
			// set ids
			var idx:uint = items
			while(idx--) conf.item[idx].id = idx
		}
			
		
		protected function initDisplay(...args):void {
			// create background and container
			background = new Bitmap()
			
			background.alpha = (100-conf.style.transparent)/100
			
			container = new Sprite()
			container.mouseEnabled = false
			
			addChild(background)
			addChild(container)
			
			// create and draw left/right buttons
			leftArea = new bitfade.ui.Empty(8,th,true);
			leftArea.name = "prev"
			leftArea.buttonMode = true
			
			rightArea = new bitfade.ui.Empty(8,th,true);
			rightArea.name = "next"
			rightArea.buttonMode = true
			
			addChild(leftArea)
			addChild(rightArea)
			
			prev = new flash.display.Shape();
			leftArea.addChild(prev)
			
			next = new flash.display.Shape()
			rightArea.addChild(next)
			
			var g:Graphics = prev.graphics
			
			var darkColorScheme:Boolean = conf.style.type == "dark"
			
			var color:uint = darkColorScheme ? 0x404040 : 0xE0E0E0
			
			g.beginFill(color,1)
			g.moveTo(12,0)
			g.lineTo(12,th/2)
			g.lineTo(0,th/4)
			g.lineTo(12,0)
			g.endFill()
			
			prev.x = 2
			
			g = next.graphics
			
			g.beginFill(color,1)
			
			g.moveTo(0,0)
			g.lineTo(0,th/2)
			g.lineTo(12,th/4)
			g.lineTo(0,0)
			g.endFill()
			
			next.y = prev.y = int((th-prev.height)/2)
				
			next.alpha = prev.alpha = 0;
			next.blendMode = prev.blendMode = darkColorScheme ? "add" : "multiply"
			
			prevTw = bitfade.utils.Tw.to(prev,0.5,null,{ease:Quad.Out})
			nextTw = bitfade.utils.Tw.to(next,0.5,null,{ease:Quad.Out})
			
			// create caption
			caption = new bitfade.ui.text.TextField({
				styleSheet:	conf.style.text is String ? conf.style.text : conf.style.text.content,
				width: 		w,
				thickness:	darkColorScheme ? -100 : 50,
				sharpness:  darkColorScheme ? 0 : -100,
				name:		"caption",
				filters: [
					new DropShadowFilter(1,45,darkColorScheme ? 0 : 0xFFFFFF,.7,1,1,1,1),
				]
			})
			addChild(caption)
			
			/*
			if (conf.external.font == "") {
				caption.thickness += 300
				caption.sharpness -= 300
			}
			*/
			
			// create seek bar
			bitfade.ui.sliders.Index.setStyle(conf.style.type)
			seekControl = new bitfade.ui.sliders.Index(100,9,80,conf.style.text is String ? conf.style.text : conf.style.text.content,seek,conf.scrollBar.autoHide);
			
			addChild(seekControl)
			
			// add listeners 
			bitfade.utils.Events.add(this,[
				MouseEvent.MOUSE_OVER,
				MouseEvent.MOUSE_OUT,
				MouseEvent.MOUSE_DOWN,
				MouseEvent.MOUSE_WHEEL
			],evHandler)
			
			// resize the thing
			resize(w,h)
			
			// set seek bar position
			cursorPos(startFrom,false)
			
			
		}
		
		// resize the component
		public function resize(nw:uint = 0,nh:uint = 0):void {
			if (!conf || !container || nw == 0 || nh == 0) return
			// set new size (if needed)
			if (!background.bitmapData || nw != w || nh != h) {
				w = nw
				h = nh
				
				// compute exact number of thumbnails to be displayed 
				var lMargin:uint = conf.thumbs.horizMargin
				max = Math.min(Math.floor((w-2*lMargin)/(tw+conf.thumbs.spacing)),items)
				step = Math.floor((w-2*lMargin)/max)
				offs = int((step-tw)/2+.5)+lMargin
				
				// compute last thumbnail index
				endOn = startFrom + max - 1
				
				// position left/right buttons
				leftArea.y = rightArea.y = container.y = h-th-bottom
				leftArea.resize(offs,th)
				rightArea.resize(offs,th)
				
				rightArea.x = w-offs
				next.x = offs-14
				
				// position caption
				description()
				
				// resize scroll bar
				seekControl.resize(w-2*offs,8)
				seekControl.x = offs
				
				// position scroll bar
				if (conf.scrollBar.show == "top") {
					seekControl.y = container.y - seekControl.height - 6
				} else {
					seekControl.y = container.y + th + bottom - seekControl.height - 4
				
				}
				
				seekControl.visible = leftArea.visible = rightArea.visible = (items > max)
				seekControl.visible = conf.scrollBar.show != "never"
				
				// redraw background
				drawBackground()
				
				// this is used by extenders
				localResize()
				
				// update display
				if (visible) update()
			}
		}
		
		protected function drawBackground() {
			Snapshot.take(bitfade.ui.backgrounds.engines.Reflection.create(conf.style.type,w,h),background)
		}
		
		// set/position caption text
		public function description(msg:String = null) {
			caption.maxWidth = w - 10
			caption.maxHeight = conf.caption.height - conf.caption.margin
			caption.content(msg)
			
			caption.x = int((w-caption.width)/2)
			
			if (conf.caption.show == "top") {
				caption.y = container.y - conf.caption.height - 10
			} else {
				caption.y = h - Math.max(conf.caption.height,caption.height)
			}			
		}
		
		// this is used by extenders
		protected function localResize():void {
		}
		
		// update display list
		protected function update():void {
		
			/*
				having this one to work in all situations was a real *PITA*
			
			*/
			var i:int
			var displayed:uint = list.length
			
			// if already have displayed thumbnails
			if (displayed > 0) {
			
				if (startFrom > first) {
					// remove thumbs from start
					removeThumbs(Math.min(startFrom - first,displayed),true) 
				} 
				
				if (endOn < last) {
					// remove thumbs from end
					removeThumbs(Math.min(last-endOn,list.length))
				}
				
				// add thumbs to start
				if (first>startFrom) {
					first = Math.min(first,startFrom+max)
					
					if (list.length == 0) {
						// no currently displayed thumbnails, add it to end
						for (i = startFrom;i<=first-1;i++) {
							addThumb(i)
						}
					} else {
						// add thumbs to start
						for (i = first-1;i>=startFrom;i--) {
							addThumb(i,true)
						}
					}
				}
				
			}
			
			// add thumbs to end
			if (endOn>last) {
				last = Math.max(last,endOn-max)
				for (i = last+1;i<=endOn;i++) {
					addThumb(i)
				}
			}
			
			// update indexes
			first = startFrom
			last = endOn
			
			// compute thumbs position
			position()
		}
		
		// compute thumbs position
		protected function position():void {
			var i:uint = list.length
			while (i--) {
				showThumb(list[i],offs+i*step,0)
			}
		}
		
		protected function loadResource(thumb:bitfade.ui.thumbs.Thumb,item:Object) {
			thumb.load(item.resource)
		}
		
		// add thumb
		protected function addThumb(i:int,head:Boolean = false) {
			
			// normalize index
			i %= items
			if (i<0) i+= items
			
			// create a new thumb or get an unused one from pool
			var thumb:bitfade.ui.thumbs.Thumb = pool.length > 0 ? pool.shift() : new bitfade.ui.thumbs.Thumb(conf.thumbs)
		
			// set scale mode
			thumb.scaleMode(conf.item[i].scale,conf.item[i].align)
			
			// load image
			loadResource(thumb,conf.item[i])
			
			// set other values
			thumb.name = i+""
			thumb.y = bottom
			thumb.alpha = 0
			
			var extraMargin:int = Math.max(0,int(conf.thumbs.horizMargin-tw))
			
			if (head) {
				thumb.x = extraMargin
				// add thumb to head	
				list.unshift(thumb)
			} else {
				// add thumb to tail
				switch (list.length) {
					case 0: thumb.x = extraMargin; break
					case max-1: thumb.x = w-tw-extraMargin; break
					default: thumb.x = int(offs+Math.min(max,list.length)*step)
				}
			
				list.push(thumb)
			}
			
			// add thumb to display list
			container.addChild(thumb)		
		}
		
		// set thumb values
		protected function showThumb(thumb:bitfade.ui.thumbs.Thumb,x:int,y: int):void {		
			thumb.x = x
			thumb.y = y
			thumb.alpha = 1
		}
		
		
		// delete thumbs
		protected function removeThumbs(n:int,head:Boolean = false):void {
			//if (n > 1 && n == max) {
			if (n > 1 && n == list.length) {
				// delete all
				var thumb:bitfade.ui.thumbs.Thumb 
				var i:uint = list.length
				while (i--) {
					thumb = list.pop()
					repool(thumb)
				}
			} else {
				// delete some
				while (n--) {
					removeThumb(head)
				}
			} 
		
			
		}
		
		// remove a single thumb
		protected function removeThumb(head:Boolean = false):void {
			var thumb:bitfade.ui.thumbs.Thumb = head ? list.shift() : list.pop()
			repool(thumb)
		}
		
		// repool an unused thumb
		protected function repool(t:bitfade.ui.thumbs.Thumb) {
			if (t.parent) container.removeChild(t)
			pool.push(t)
			t.reset()
		}
		
		// clean up resources
		public function destroy():void {
			Gc.destroy(this)
		}
		
 		// scroll to position p: 0 (first) -> 1 (last)
		protected function seek(p:Number) {
			advance(Math.min(Math.floor((items-max+1)*p),items-max),true)
			seekControl.content("<index>"+Math.min(items,Math.floor(items*p+1))+"</index>");
		}
		
		// set scroll bar index position
		public function cursorPos(n:int,useTween:Boolean = true,show:Boolean = true) {
			seekControl.content("<index>"+(n+1)+"</index>",show);
			seekControl.pos(n/(items-1),useTween)			
		}
		
		// get real start index
		public function get startIndex():uint {
			var idx:int = startFrom % items
			if (idx<0) idx+= items
			return idx
		}
		
		// advance (cycle) thumbnails
		public function advance(n:int,absolute:Boolean = false):void {
			if (scrollLock) return
			Run.after(0.05,scrollUnlock,scrollUnlockTimer)
					
			scrollLock = true
			
			if (absolute) {
				// some math: hard to explain but it works
				var delta:int = startFrom % items
				if (delta<0) delta+= items
				
				delta = n-delta
				
				// if delta = 0, nothing to do 
				if (delta == 0) return
				
				
				if (Math.abs(delta) > items/2) delta += items
				
				startFrom += delta
			} else {
				startFrom += n
			}
			
			endOn = startFrom + max - 1
			
			
			if (visible) {
				update()
			} else {
				// update indexes
				startFrom = startIndex
				startIndex = startFrom
			}
			
						
		}
		
		// handle all events
		protected function evHandler(e:*):void {
		
			// stop events propagation
			e.stopPropagation()
			e.stopImmediatePropagation()
			
			var id:String = e.target.name
			
			switch (e.type) {
				case MouseEvent.MOUSE_WHEEL:
					if (id != "caption" || caption.maxScrollV == 1) advance(e.delta > 0 ? -1 : 1)
				break;
				case MouseEvent.MOUSE_OVER:
				case MouseEvent.MOUSE_OUT:
				
					var mouseOver:Boolean = (e.type == MouseEvent.MOUSE_OVER)
					
					switch (id) {
						case "thumbs":
						case "caption":
						break
						default:
							if (e.target is bitfade.ui.Empty) {
								// show/hide prev/next buttons
								if (id == "prev" || id == "next") {
									var t:bitfade.utils.Tw = this[id+"Tw"]
									t.proxy.alpha = (mouseOver ? 1 : 0)
									t.onComplete = null
								}
							} else if (e.target is bitfade.ui.thumbs.Thumb){
								// hilight thumb
								e.target.over(mouseOver)
								if (mouseOver) {
									// show scroll bar
									if (conf.item[parseInt(id)].caption) description(conf.item[parseInt(id)].caption[0].content)
									cursorPos(parseInt(id),true,conf.scrollBar.showOnOver)
									if (conf.thumbs.spacing < 0) container.addChild(e.target)
									
									
									
								}								
							}
						break
						
					}
					
				break
				case MouseEvent.MOUSE_DOWN:
					if (e.target is bitfade.ui.thumbs.Thumb) {
						// get the link
						var item:Object = conf.item[parseInt(id)]
						
						if (clickCallback != null) {
							// call user defined callback
							clickCallback(clickCallbackValues ? item : item.link)
						} else if (conf.openUrl && item.link) {
							// open it
							openUrl(item)
						}
												
					} else {
						switch (id) {
							case "prev":
							case "next":
								// prev/next page
								var page:int = Math.max(Math.min(items-max,max),0)
								if (page > 0) advance(id == "prev" ? -max : max)
								cursorPos(startIndex)
							break;	
						}
					}
					
				break;
			}
		}
		
		public function openUrl(item:Object) {
			ResLoader.openUrl(item.link,item.target)
		}
		
		public function clickHandler(clickCallback:Function,fullValues:Boolean = false) {
			this.clickCallback = clickCallback
			clickCallbackValues = fullValues
			conf.openUrl = (clickCallback == null)
		}
		
		// unlock scroll
		protected function scrollUnlock() {
			scrollLock = false
		}
		
		// hide scroller
		public function hide() {
			show(false)
		}
		
		protected function hideMe(t:bitfade.utils.Tw) {
			t.onComplete = null
			t.delay = 2
			t.proxy.alpha = 0
			t.position = -1
		}
		
		// enlight effect
  		protected function fadeLoopRunner(ratio:Number,show:Boolean) {
  			locked = ratio != 1
  			ratio = show ? ratio : 1-ratio
  			alpha = ratio
  			visible = alpha > 0
  			
  			if (ratio == 1) {
				if (show) {
					prevTw.onComplete = nextTw.onComplete = hideMe
					prevTw.proxy.alpha = nextTw.proxy.alpha = 1
				} else {
					prev.alpha = next.alpha = 0
				}
			} 
  			
  			if (!visible && !show) {
  				removeThumbs(list.length)
  				
				first = startFrom
				last = startFrom-1
  			}
  		}
		
		// show scroller
		public function show(sw:Boolean = true) {
			if (locked || (visible == sw) ) return
			if (sw) {
				update()
				cursorPos(startFrom,false)
			}
			fadeLoop = Run.every(Run.FRAME,fadeLoopRunner,8,0,true,fadeLoop,sw)
		}
		
		public function get all():Array {
			return conf.item
		}
		
		// set start index
		public function set startIndex(idx:uint) {
			startFrom = idx
			endOn = startFrom + max - 1
			first = startFrom
			last = startFrom-1
		}
		

	}
}
/* commentsOK */