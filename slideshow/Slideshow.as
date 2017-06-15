/*

	This is a base class used as a start for effects slideshow 
	No magic here, just some common methods.

*/
package bitfade.slideshow {

	import flash.display.*
	import flash.events.*
	import flash.geom.*
	import flash.text.*
	import flash.utils.*
	import flash.filters.*
	
	import bitfade.display.panzoom
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.transitions.simple
	
	public class slideshow extends Sprite {
		
		// here we keep configuration
		protected var conf:Object
		
		// some defaults, ** SEE HELP FILE ** all covered there
		// these are overwrited by xml settings, so no need to change here
		
		protected var defaults:Object = {
			order: "sequential",
		
			timings: {
				panZoomSpeed: 1, 
				fade: 1,
				effect : 0,
				delay: 4
			},
			item: {
				transition: "fade",
				scale: "fill",
				align: "random",
				pan: "random",
				zoom: "random",
				animated: "false",
				loop: true,
				
				target: "_new",
				duration: 0,
				width: 0,
				height: 0		
			},
			transition: {
				random: ["fade","saw","slideLeft"],
				prev: "slideRight",
				next: "slideLeft"
			},
			caption: {
				show: "over",
				align: "bottom",
				embedFonts: false,
				margins: "2,5",
				size: 40,
				
				followTransition: false,
				
				background: {
					color: 0x202020,
					startAlpha:1,
					endAlpha:0.8
				},
				
				shadow: {
					enabled: true,
					size: 1,
					angle: 45,
					color: 0,
					alpha: 1,
					blur: 1,
					strength: 1
				}
			},
			controls: {
				show: "over",
				
				clickDisablePause: true,
				pauseShowControls: true,
				forceTransition: true,
				autoPause: false,
				
				
				align: "bottom,right",
				margins: "15,5",
				
				prev: true,
				pause: true,
				next: true,
				size: 20,
				spacing: 4,
				
				background: {
					color: 0xFFFFFF,
					alpha: 0.8
				},
				
				border: {
					size: 2,
					color: 0,
					alpha: 0.6
				},
				
				controlBorder: {
					size: 1,
					color: 0,
					alpha: 0.4
				},
				
				color: 0x808080,
				alpha: 1
			},
			spinner: {
				enabled: true
			}
		}
	
		// resource loader for external files
		protected var rL:resLoader
		
		// some bitmapDatas
		public var bMap:Bitmap
		public var bData:BitmapData
		protected var bDraw:BitmapData
		protected var bBuffer:BitmapData
		
		// caption bitmapDatas
		protected var bCaption:BitmapData
		protected var bCaptionOld:BitmapData
		protected var bCaptionBuffer:BitmapData
		protected var bCaptionBackground:BitmapData
		
		// caption transition manager
		protected var captionTransition: bitfade.transitions.simple
		
		// for text rendering
		protected var textR:TextField;
		
		// common geom stuff 
		protected var origin:Point;
		protected var captionPt:Point;
		
		// for holding current Item
		protected var currentItem:Object
		protected var currentItemIdx:uint = 0
		
		// for holding pan & zoom objects
		protected var pz:panzoom;
		protected var prevPz:panzoom;
		
		// true when item is inited
		protected var inited:Boolean = false;
				
		// default box
		protected var box:Rectangle
		
		// spinner
		protected var loadSpinner:spinner;
		
		// dimentions
		protected var w:uint
		protected var h:uint
		
		// counters
		protected var counter:Number = 0
		protected var counterMax:Number = 1000
		protected var overCounter:uint = 0
		protected var overCounterMax:uint = 10
		
		// true when cursor over window
		protected var mouseOver:Boolean = false
		
		// slideshow status codes
		public static const PAUSE:uint = 0
		public static const WAIT:uint = 6
		public static const LOADING:uint = 1
		public static const FADE_IN:uint = 2
		public static const EFFECT:uint = 3
		public static const FADE_OUT:uint = 4
		public static const LOAD_NEXT:uint = 5
		
		// status
		protected var status:uint = PAUSE
		
		// slideshow controls container
		protected var controls:Sprite
		
		// true when paused
		protected var paused:Boolean = false
		
		// images/swfs transition manager
		protected var transition: bitfade.transitions.simple
		
		// drop shadow filter
		protected var dsF:DropShadowFilter
		
		// constructor
		public function slideshow(conf) {
		
			// create the loader
			rL = new resLoader(itemLoaded)
			
			if (conf is XML) {
				// local conf, just parse
				configure(conf)
			} else {
				// if conf is external, load it
				rL.add(conf,configure)
			}
		}	
		
		// used to convert seconds in frames
		private function convertTimings(v,k) {
			return parseFloat(v)*(k != "panZoomSpeed" ? conf.fps : 1)
		}
		
		// return a random index
		protected function getRandomIdx():Number {
			return Math.round(Math.random()*(conf.item.length-1))
		}
		
		// init stuff
		protected function init(e:Event=null) {
			
			name = "main"
			
			conf.fps = stage.frameRate			
			conf.item = []
			
			// for each item group
			for each (var group in conf.group) {
				
				// get group defaults
				var groupDefaults = {}
				groupDefaults.timings = misc.setDefaults(group,defaults.timings,true)
				
				groupDefaults.item = misc.setDefaults(group,defaults.item,true)
				
				// for each item in group
				for (var idx in group.item) {
					
					var item:Object = group.item[idx];
					
					// set group defaults
					if (group.basepath) item.resource = group.basepath + "/" + item.resource
				
					item.timings = misc.setDefaults(item,groupDefaults.timings,true,convertTimings)
					
					conf.item.push(misc.setDefaults(item,groupDefaults.item))
					
				}

			}
			
			
			// set defaults for caption, controls, transition and spinner
			for each (var opt in ["caption","controls","transition","spinner"]) {
				conf[opt] = conf[opt] ? misc.setDefaults(conf[opt][0],defaults[opt]) : defaults[opt]
			}
			
			if (!conf.order) conf.order = defaults.order
			
			currentItemIdx = conf.order == "sequential" ? 0 : getRandomIdx()
			
			// if already inited, no more init stuff
			if (inited) {
				return nextItem()
			}
		
			try {
				// remove the event listener, if exist
				removeEventListener(Event.ADDED_TO_STAGE,init)
			} catch (e) {}
			
			
			// set some values using configuration
			if (!conf.width) conf.width = stage.stageWidth
			if (!conf.height) conf.height = stage.stageHeight
			
			
			// build the text field
			textR = new TextField();
			
			with (textR) {
				width = w = conf.width
				height = h = conf.height
				
				// embedFonts is controlled by caption xml settings
				embedFonts  = conf.caption.embedFonts
			
				border = false
				background = false
				condenseWhite = true
				multiline = true
				selectable = false
				
				var sheet = new StyleSheet();
				// stylesheet is in xml too
				sheet.parseCSS(conf.style[0].content)
				
				styleSheet = sheet;
			}
			
			
			// create bitmaps
			bData = new BitmapData(w,h,true,0);
			bMap = new Bitmap(bData)
			bDraw = bData.clone()
			bBuffer = bData.clone()
			
			// create the main transitions manager
			transition = new simple(bDraw,bBuffer)
			
			// if caption is not disabled, create the stuff needed to draw it
			with (conf.caption) {
				if (show != "never") {
					bCaption = new BitmapData(w,size,true,0);
					bCaptionOld = bCaption.clone()
					bCaptionBuffer = bCaption.clone()
					bCaptionBackground = bCaption.clone()
					
					buildCaptionBackground()
					
					// caption transitions manager
					captionTransition = new simple(bCaptionBuffer)
					
					// crossfade = true 'cause caption uses alpha
					captionTransition.crossFade = true
					
					// drop shadow filter
					with (shadow) {
						dsF = new DropShadowFilter(size,angle,color,alpha,blur,blur,strength,1)
					}
					
					// split margins
					conf.caption.margins = geom.splitProps(conf.caption.margins,true)
					
				}
			}
			
			// add bitmap
			addChild(bMap)
			
			// create controls
			buildControls()
			
			// create spinner, if not disabled
			if (conf.spinner.enabled) {
				loadSpinner = new spinner({x:w/2-15,y:h/2-15})
				addChild(loadSpinner)
			}
			
			
			// some more geom stuff
			origin = new Point()
			captionPt = new Point(0,conf.caption.align == "bottom" ? h-conf.caption.size : 0)
			box = new Rectangle(0,0,w,h)
			
			
			// call custom init used by extenders
			customInit()
			inited = true
			
			// add enter_frame event listener
			addEventListener(Event.ENTER_FRAME,frameHandler)
			
			// add events handler
			for each (var ev:String in [MouseEvent.CLICK,MouseEvent.ROLL_OVER,MouseEvent.ROLL_OUT]) {
				addEventListener(ev,eventHandler)
			}
			
			// let's rock
			nextItem()
		}
		
		// build controls
		protected function buildControls() {
			
			// if disabled, no need to build
			if (conf.controls.show == "never") return
			
			// controls container
			controls = new Sprite(); 
			
			var xp:uint = 0;
			var ac:uint = 0;
			
			// for each button
			for each (var c:String in ["prev","pause","next"]) {
				
				// if not enabled, go next one
				if (!conf.controls[c]) continue
				
				ac++
				
				// create and draw the button
				conf.controls[c] = new Sprite()
				controls.addChild(conf.controls[c])
				
				var size = conf.controls.size
				
				with (conf.controls[c]) {
					buttonMode = true
			
					alpha = 0.8
					name = c
					x = xp
					
					var bsize:Number = size*0.4
					var boff:Number = (size-bsize)/2
					
					
					with (graphics) {
						// draw background
						lineStyle(conf.controls.border.size,conf.controls.border.color,conf.controls.border.alpha)
						beginFill(conf.controls.background.color,conf.controls.background.alpha)
						
						drawRoundRect(0,0,size,size,8,8)
						
						endFill()
						
						// draw button
						lineStyle(conf.controls.controlBorder.size,conf.controls.controlBorder.color,conf.controls.controlBorder.alpha,true)
						beginFill(conf.controls.color,conf.controls.alpha)
						
						switch (name) {
							case "prev":
								moveTo(boff+bsize,boff+bsize)
								lineTo(boff+bsize,boff)
								lineTo(boff,boff+bsize/2)
								lineTo(boff+bsize,boff+bsize)
							break;
							case "next": 
								moveTo(boff,boff)
								lineTo(boff,boff+bsize)
								lineTo(boff+bsize,boff+bsize/2)
								lineTo(boff,boff)
							break
							default:
								drawRect(boff+bsize/8,boff,bsize*2/8,bsize)
								drawRect(boff+bsize*5/8,boff,bsize*2/8,bsize)
						}
					}
				}
				// add spacing
				xp += (size+conf.controls.spacing)
				
			}
			
			// if ac == 0, no button enabled
			if (ac == 0) return
			
			var offs:Object
			
			// use defined controls margins
			with (conf.controls) {
				offs = {
					w: w-(controls.width),
					h: h-(controls.height)
				}
			
				align = geom.splitProps(align)
				margins = geom.splitProps(margins,true)
				
				// use controls align to position
				for (d in align) {
					
					switch (align[d]) {
						case "center":
							offs[d] /= 2
						break
						case "left":
						case "top":
							offs[d] = margins[d]
						break;
						default:
							offs[d] -= margins[d]
					}
					
				}
			}
			
			// set computed offsets 
			with (controls) {
				x = offs.w
				y = offs.h
				alpha = 0
			}
			
			// add event listeners
			for each (var ev:String in [MouseEvent.CLICK,MouseEvent.MOUSE_OVER,MouseEvent.MOUSE_OUT]) {
				controls.addEventListener(ev,eventHandler)
			}
			
			// add controls
			addChild(controls)
			
		}
		
		
		// do nothing
		protected function customInit() {
		}
		
		// draw current item
		protected function draw(data) {
		
			// get item panzoom configuration
			var pzConf:Object = misc.setDefaults(currentItem,defaults.item,true)
			
			// set some other values
			with (currentItem.timings) {
					misc.setDefaults(pzConf,{
					duration: (fade*2+delay)/panZoomSpeed,
					width: 0,
					height: 0,
					targetWidth: currentItem.width ? currentItem.width : 0,
					targetHeight: currentItem.height ? currentItem.height : 0
				})
			}
			
			
			// overwrite width/height
			with (pzConf) {
				width = w
				height = h
			}
			
			// fix to banners which initializes only when added to displayList
			if (!(data is BitmapData)) {
				data.visible = false;			
				addChild(data)
				removeChild(data)
			}
		
			// create the panzoom element
			pz = new panzoom(data,pzConf)
			
			// draw caption
			drawCaption()
		}
		
		
		// this will load next item
		public function nextItem(e=null) {
		
			// change status
			status = LOADING
			
			// increment counter
			if (conf.order == "random") {
				// random mode
				currentItemIdx = getRandomIdx()+1
			} else if (currentItemIdx < conf.item.length) {
				currentItemIdx++
			} else {
				// last item  
				if (conf.order != "random" && conf.noloop) {
					// noloop mode, destroy
					return destroy()
				} else {
					// loop mode, start from first
					currentItemIdx = 1
				}
			}
			
			// get current item
			currentItem = conf.item[currentItemIdx-1]
			
			// show load spinner
			if (conf.spinner.enabled) loadSpinner.show(300);
			
			// load current item
			rL.add(currentItem.resource)
			// preload next item (if not random mode)
			if (conf.order != "random")	rL.add(conf.item[currentItemIdx % conf.item.length].resource,false)	
		}
		
		// this gets called when item is loaded
		protected function itemLoaded(data) {
			// stop spinner
			if (conf.spinner.enabled) loadSpinner.hide()
			// update item
			updateItem(data)
		}
		
		// this will update current item with new loaded one
		protected function updateItem(data) {
			// draw new item
			draw(data)
			counter = 0
			counterMax = 5
			
			// take care of item transition type
			
			var choosed:String = currentItem.transition
			
			if (conf.transition.forceNext) {
				choosed = conf.transition.forceNext
				conf.transition.forceNext = false
			} else if (choosed == "random") {
				choosed  = conf.transition.random[uint(Math.random()*(conf.transition.random.length-1)+0.5)]
			} 
			
			currentItem.choosedTransition = choosed
			
			// change status
			status = FADE_OUT
			
			// if has link, show hand cursor
			buttonMode = currentItem.link ? true : false
		}
		
		// fade old item and show new one
		protected function fadeIn() {
			var source = null
			
			// old item exists, update panzoom for it
			if (prevPz) {
				prevPz.update()
				source = prevPz.bData
			} 
			
			// update panzoom for current item
			pz.update()
			
			// gogo transition
			transition.crossFade = (currentItem.scale == "fit")
			transition[currentItem.choosedTransition](source,pz.bData,counter,counterMax)
			
			// draw transition on screen
			render(bDraw)
		}
		
		// do nothing
		protected function effect() {
		}
		
		// wait -> render
		protected function wait() {
			render()
		}
		
		// loading -> render
		protected function loading() {
			render()
		}
		
		// fade out
		protected function fadeOut() {
			// do nothing, just jump to next status
			counter = counterMax
		}
		
		// draw stuff on screen
		protected function render(bd:BitmapData=null) {
		
			if (!bd) {
				// no bitmap on params, so just update current panzoom
				pz.update()
				bd = pz.bData
			} 
			
			// copy current data (bd) on screen
			bData.copyPixels(bd,box,origin)
			
			// render caption
			renderCaption();
			
			// render controls
			renderControls();
		}
		
		// build caption background
		protected function buildCaptionBackground() {
			
			// get config values
			var startAlpha:uint = uint(conf.caption.background.startAlpha*0xFF)
			var endAlpha:uint = uint(conf.caption.background.endAlpha*0xFF)
			var color:uint = conf.caption.background.color
			
			var alpha:uint = 0
			
			var r=new Rectangle(0,0,w,1)
			
			// draw the gradient
			for (var yp:uint=0;yp<bCaptionBackground.height;yp++) {
					r.y = yp
					alpha = uint(Expo.Out(yp+1,startAlpha,endAlpha-startAlpha,bCaptionBackground.height+1)) << 24
					bCaptionBackground.fillRect(r,color + alpha)
			}
		}
		
		// draw caption
		protected function drawCaption() {
			
			// if caption not showed, no need to draw anything
			if (conf.caption.show == "never") return
			
			// copy old caption
			bCaptionOld.copyPixels(bCaption,bCaption.rect,origin)
			bCaption.fillRect(bCaption.rect,0)
			
			// if current item has caption, draw it
			if (currentItem.caption) {
				textR.htmlText = currentItem.caption[0].content
				
				bCaption.fillRect(bCaption.rect,0)
				
				bCaption.draw(textR,geom.getTranslateMatrix(conf.caption.margins.w,conf.caption.margins.h))
				
				if (conf.caption.shadow.enabled) bCaption.applyFilter(bCaption,box,origin,dsF)
				
			}
		}
		
		// render current caption
		protected function renderCaption() {
		
			// if caption not showed, no need to draw anything
			if (conf.caption.show == "never" || !currentItem.caption) return
			
			var ff:Number = 1;
			
			// if caption mode is "over", take overCounter factor
			if (conf.caption.show == "over") {
				if (overCounter == 0) return
				ff = overCounter/overCounterMax
			} 
			
			var captionRect:Rectangle = bCaption.rect
			
			// draw caption background
			bBuffer.fillRect(captionRect,uint(ff*0xFF*(conf.firstFaded ? 1 : counter/counterMax )) << 24)
			bData.copyPixels(bCaptionBackground,captionRect,captionPt,bBuffer,origin,true)
			
			
			if (status == FADE_IN) {
				// if fade in, gogo caption transition
				var choosed:String = currentItem.choosedTransition
				if (!conf.caption.followTransition) {
					if (!(choosed == "slideLeft" || choosed == "slideRight")) choosed = "slideBottom"
				} 
				captionTransition[choosed](bCaptionOld,bCaption,counter,counterMax)
				bData.copyPixels(bCaptionBuffer,captionRect,captionPt,bBuffer,origin,true)
				
			} else {
				// no fade in, just draw the caption
				bData.copyPixels(bCaption,captionRect,captionPt,bBuffer,origin,true)
			}

		}
		
		// render controls
		protected function renderControls() {
			switch (conf.controls.show) {
				case "over":
					// if paused, do nothing
					if (paused && conf.controls.pauseShowControls && controls.alpha == 1 ) return
					// set alpha
					controls.alpha = overCounter/overCounterMax
				break
				case "always":
					// if controls are already visible, do nothing
					if (conf.controls.active) break
					if (status == FADE_IN) {
						// take care of FADE_IN status
						controls.alpha = counter/counterMax
					} else {
						// controls ok
						conf.controls.active = true
						controls.alpha = 1
					}
			}	
		}
		
		// handle the logic
		protected function frameHandler(e:Event) {	
			switch (status) {
				case FADE_IN:
					fadeIn();
					counter++
					if (counter >= counterMax) {
						// fade in ended
						conf.firstFaded = true
					
						if (prevPz) {
							prevPz.destroy()
						}
						prevPz = pz
						counter = 0
						
						if (currentItem.timings.effect) {
							counterMax = currentItem.timings.effect
							status = EFFECT
						} else {
							// jump to wait loop
							counterMax = currentItem.timings.delay
							status = WAIT
						}
					}
				break;
				// not used
				case EFFECT: 
					effect();
					counter++
					if (counter >= counterMax) {
						counter = 0
						counterMax = currentItem.timings.delay
						status = WAIT
					}
				break;
				case WAIT: 
					wait();
					if (!paused) counter++
					if (counter >= counterMax) {
						// wait delay ended, load next item
						status = LOAD_NEXT
						nextItem()
					}
				break;
				
				case FADE_OUT:
					// not used 
					fadeOut();
					counter++
					if (counter >= counterMax) {
						// jump to FADE_IN
						counter = 0
						counterMax = currentItem.timings.fade
						status = FADE_IN
					}
				break;
				case LOADING:
					// call loading (-> render)
					loading();
				break;
			}
			
			// if mouse over slideshow, update counter
			if (mouseOver) {
				if (overCounter < overCounterMax) overCounter++
			} else if (overCounter > 0) {
				overCounter--
			}
			
		}
		
		// pause slideshow
		protected function setPause(p:Boolean) {
			paused = p
			if (conf.controls.pause) controls.getChildByName("pause").alpha = paused ? 1 : 0.8
		}
		
		// event handler for controls and main click
		protected function eventHandler(e:Event) {
			var tname:String = e.target.name 
			
			// stop event
			e.stopPropagation()
			
			switch (e.type) {
				// click event
				case MouseEvent.CLICK:
					// do nothing if LOADING of FADE_IN
					if (status == LOADING || status == FADE_IN) break;
					switch (tname) {
						case "pause":
							// pause slideshow
							setPause(!paused)
						break
						case "prev":
						case "next":
							// prev, next buttons
							if (!conf.controls.autoPause && conf.controls.clickDisablePause && paused) setPause(false) 
							
							if (tname == "prev") {
								currentItemIdx = Math.min(uint(currentItemIdx-2),conf.item.length-1)
							}
							conf.transition.forceNext = (conf.controls.forceTransition) ? conf.transition[tname] : false
							if (status != FADE_IN) {
								counter = counterMax
							}
						break;
						default:
							// main item clicked, open url
							ResLoader.openUrl(currentItem.link,currentItem.target)
					}
				break
				case MouseEvent.ROLL_OVER:
					// mouse over
					mouseOver = true
					if (conf.controls.autoPause) setPause(true)
				break;
				case MouseEvent.MOUSE_OVER:
					// mouse over control button
					e.target.alpha = 1
				break
				case MouseEvent.ROLL_OUT:
					// mouse out
					mouseOver = false
					if (conf.controls.autoPause) setPause(false)
				break;
				case MouseEvent.MOUSE_OUT:
					// mouse out countrol button
					if (!(tname == "pause" && paused))	e.target.alpha = 0.8
				break
			}
		}
		
		// destructor
		public function destroy() {
			
			var ev:String
			
			// remove all events listeners
			try {
				removeEventListener(Event.ADDED_TO_STAGE,init)
			} catch (e) {}
			
			try {
				for each (ev in [MouseEvent.CLICK,MouseEvent.MOUSE_OVER,MouseEvent.MOUSE_OUT]) {
					controls.addEventListener(ev,eventHandler)
				}
			} catch (e) {}	
			
			for each (ev in [MouseEvent.CLICK,MouseEvent.ROLL_OVER,MouseEvent.ROLL_OUT]) {
				removeEventListener(ev,eventHandler)
			}
			
			removeEventListener(Event.ENTER_FRAME,frameHandler)
			// remove the instance
			parent.removeChild(this)
		}
		
		// this will parse xml configuration
		public function configure(xmlConf,id=null,url=null) {
			// override defaults with xml settings
			conf=xmlParser.toObject(xmlConf)
			
			if (stage) {
				// if stage exist, init
				init()
			} else {
				// otherways, wait until item is added
				addEventListener(Event.ADDED_TO_STAGE,init)
			}
		}
		
			
	}

}
	