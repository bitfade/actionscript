/*

	This is a base class used by all my text.effects
	No magic here, just some common methods.

*/
package bitfade.text {

	import flash.display.*
	import flash.events.*
	import flash.text.*
	import flash.geom.*
	import flash.utils.Timer
	import flash.utils.getDefinitionByName
	
	import bitfade.utils.*
	import bitfade.presets.gradients
	
	public class effect extends Sprite {
		
		// here we keep configuration
		protected var conf:Object
		
		// some defaults, no need to change here as everything is set in xml config
		protected var defaults:Object = {
			conf: {
				width: 0,
				height: 0,
				noloop: false
			},
			transition: {},
			item: {},
			timings: {
				duration: 3,
				delay: 0
			}
		}
	
		// resource loader for external files
		protected var rL:resLoader
		
		// for text rendering
		protected var textR:TextField;
		protected var textF:TextFormat;
		
		// some bitmapDatas
		public var bMap:Bitmap
		public var bData:BitmapData
		protected var bDraw:BitmapData
		protected var bBuffer:BitmapData
	
		
		// color transform used to draw symbols
		protected var drawCT:ColorTransform
		
		// catch mouse clicks
		protected var clickArea:Sprite;
		
		// common geom stuff 
		protected var pt:Point;
		protected var origin:Point;
		protected var hitR:Rectangle;
		protected var colorMap:Array
		
		// for holding current Transition and Text
		protected var currTransition:Object
		protected var currText:Object = {}
		protected var currTransitionIdx:uint = 0
		protected var currTextIdx:uint = 0
		
		// semaphore used to lock effect while updating text
		protected var ready:Boolean = false;
		protected var inited:Boolean = false;
		
		// timer for delay
		protected var tim:Timer;
		
		// default box
		protected var box:Rectangle
		
		// dimentions
		protected var w:uint
		protected var h:uint
		
		// counter
		protected var counter:uint = 0;
		protected var counterMax:uint = 0;
		
		// constructor
		public function effect(conf=null) {
		
			// build the text field
			textR = new TextField();
			textF = new TextFormat("Arial",100,0);
			
			with (textR) {
				border = false
				background = false
				condenseWhite = true
				multiline = true
				selectable = false
				defaultTextFormat = textF
			}
			
			// color transform used to draw objects
			drawCT = new ColorTransform(0,0,0,1,0,0,0,0)

			// build the color map
			colorMap = new Array(256)
			buildColorMap()	
			
			// initialize timer
			tim = new Timer(1000,1)
			tim.addEventListener(TimerEvent.TIMER, updateText);
			
			setDefaults()
			
			// create the resource loader
			rL = new resLoader()
				
			if (conf is XML) {
				// local conf, just parse
				configure(conf)
			} else if (conf) {
				// if conf is external, load it
				rL.add(conf,configure)
			} else {
				// no conf defined, try to get it from paramers
				addEventListener(Event.ADDED_TO_STAGE,getConfigFromParameters)
			}
		}	
		
		// no conf defined, try to get it from paramers
		protected function getConfigFromParameters(e) {
			removeEventListener(Event.ADDED_TO_STAGE,getConfigFromParameters)
			var conf  = "config.xml"
			// try to get config parameters, fallback is to use default conf
			try {
				if (loaderInfo.parameters.config) conf = loaderInfo.parameters.config
			} catch(e) {}
			// load conf
			rL.add(conf,configure)
		}
		
		// can be overridden by extenders
		protected function setDefaults() {
		}
		
		// here we set font
		protected function setFont(name,size) {
		
			// some defaults
			if (name == undefined) name="Arial"
			if (size == undefined) size=100
		
			textF.font = name
			textF.size = size;
			
			textR.embedFonts = false;	
			
			// this snippet will autodetect embedded fonts
			var fontList:Array = Font.enumerateFonts(false);
			for (var i:uint=0; i<fontList.length; i++) {
				if (fontList[i].fontName == name) {
					textR.embedFonts = true;
					break
				}
			}
			textR.defaultTextFormat = textF
		}
		
		// reset counter and set a new max
		protected function resetCounter(max) {
			counter = 1
			counterMax = max
		}
		
		// used to convert seconds in frames
		protected function convertTimings(v,k) {
			return parseFloat(v)*(k == "delay" ? 1000 : stage.frameRate)
		}
		
		protected function fontsLoaded(data) {
			conf.fontsLoaded = true
			init()
		}
		
		// init stuff
		protected function init(e:Event=null) {
		
			// load external fonts, if needed
			if (conf.fonts && !conf.fontsLoaded) {
				var externalFonts:Array = []
				for each (var font in conf.fonts[0].font) {
					externalFonts.push("font|"+font.resource)
				}
				return rL.add(externalFonts,fontsLoaded)
			}
			
			// set conf defaults
			misc.setDefaults(conf,defaults.conf)
			
			
			// fix some values in transitions
			for each (var t:Object in conf.transition) {
				
				// override defaults for timings
				misc.setDefaults(t,defaults.timings,false,convertTimings)
				
				// override defaults for other values
				misc.setDefaults(t,defaults.transition)
				
				// if delay defined
				if (t.delay) {
					t.delayFrames = uint(t.delay*stage.frameRate/1000)
				}	
								
				// if custom color defined, let's deal with it
				if (t.color) {
					var c:String = t.color
					if (c.charAt(0) == "#") {
						t.color = parseInt("0x" + c.substr(1))
					} else if (c.charAt(0) == "[") {
						t.color = (c.substr(1,c.length-2)).split(",").map(function (v) { return parseInt(v)})
					}
				}
				
				// set items defaults
				for (var idx:uint = 0;idx<t.item.length;idx++) {
					misc.setDefaults(t.item[idx],defaults.item)
				}
				
			
				
			}
		
			// if already inited, no more init stuff
			if (inited) {
				currTransitionIdx = 0
				return updateTransition()
			}
		
			try {
				// remove the event listener, if exist
				removeEventListener(Event.ADDED_TO_STAGE,init)
			} catch (e) {}
			
			
			// set some values using configuration
			if (!conf.width) conf.width = stage.stageWidth
			if (!conf.height) conf.height = stage.stageHeight
			
			
			textR.width = w = conf.width
			textR.height = h = conf.height
			
			// create bitmaps
			bData = new BitmapData(w,h,true,0);
			bMap = new Bitmap(bData)
			
			bDraw = bData.clone()
			bBuffer = bData.clone()
			
			// if config include "centered", add a layout manager
			if (conf.centered) {
				layout()
				stage.addEventListener(Event.RESIZE,layout)
			}
			
			// add bitmap
			addChild(bMap)
			
			// create the clickArea area
			clickArea = new Sprite()
			clickArea.buttonMode = true
			clickArea.addEventListener(MouseEvent.CLICK,clickHandler)
			
			addChild(clickArea)
			
			// some more stuff
			pt = new Point();
			origin = new Point()
			box = new Rectangle(0,0,w,h)
			
			
			// call custom init used by extenders
			customInit()
			inited = true
			
			// let's rock
			updateTransition()
			
		}
		
		// handle mouse clicks
		protected function clickHandler(e) {
			ResLoader.openUrl(currText.link,'_self')
		}
		
		// this will set a clickable area with the same size as current text
		protected function setClickArea() {
			if (currText.link) {
				with (clickArea.graphics) {
					clear();
					beginFill(0,0)
					drawRect(pt.x,pt.y,hitR.width,hitR.height)  
				}
				clickArea.visible = true
			} else {
				clickArea.visible = false
			}
		}
		
		// do nothing
		protected function customInit() {
		}
		
		// keep stuff centered
		protected function layout(e=null) {
			bMap.x = (stage.stageWidth - w)/2
			bMap.y = (stage.stageHeight - h)/2
			
		}
		
		// this crop text so that only real text area is used
		protected function hitBox(bm:BitmapData):Rectangle {
			var xs:uint=0
			var xe:uint=w
			var ys:uint=0
			var ye:uint=h
			
			var hb = new Rectangle(0,0,1,h)
			
			with (hb) { x=0;y=0;width=1;height=h }
			while (!bm.hitTest(origin,0x01,hb)) if (++hb.x > w-1) break;
			xs = hb.x
			hb.x=w-1
			while (!bm.hitTest(origin,0x01,hb)) if (--hb.x < 1) break;
			xe = hb.x
			with (hb) { x=0;y=0;height=1;width=w }
			while (!bm.hitTest(origin,0x01,hb)) if (++hb.y > h-1) break;
			ys = hb.y
			hb.y=h-1
			while (!bm.hitTest(origin,0x01,hb)) if (--hb.y < 1) break;
			ye = hb.y
			with (hb) { x=xs,y=ys,width=xe-xs+1,height=ye-ys+1}
			return hb
		}
		
		

		// draw current text line
		protected function draw(data=null) {
			
			bBuffer.fillRect(box,0)
			
			if (data) {
				bBuffer.draw(data,null,drawCT,null,null,true)
			} else if (currText.type == "class") {
				var rtClass:Class = Class(getDefinitionByName(currText.content));
				var rtObject = new rtClass()
				bBuffer.draw(rtObject,null,drawCT,null,null,true)
			} else {
				textR.htmlText = currText.content
				bBuffer.draw(textR,null,null,null,null,true)
			}
			
			
			
			hitR = hitBox(bBuffer)
			bDraw.fillRect(bDraw.rect,0)
			bDraw.copyPixels(bBuffer,hitR,origin)
			
			with (hitR) {
				x = 0
				y = 0
				pt.x = (w - width)/2
				pt.y = (h - height)/2
			}

		}
		
		// update text line
		public function updateText(e=null) {
		
			if (!e && currTransition.delay > 0) {
				// manage delay
				if (!tim.running) {
					tim.delay = currTransition.delay 
					tim.start()
				}
				return
			} 
			
			conf.firstRun = (conf.firstRun == null) ? true : false
			
			// if last line of text, update transition
			if (currTextIdx < currTransition.item.length) {
				currTextIdx++
			} else {
				return updateTransition()
			}
			
			
			
			var cT:Object = currTransition.item[currTextIdx-1]
			
			// loader code here
			if (cT.type == "external") {
				rL.add(cT.content,contentLoaded)
			} else {
				contentLoaded()
			}			
			
		}
		
		protected function contentLoaded(data=null) {
			ready = false
			
		
			
			currText = currTransition.item[currTextIdx-1]
			currText.pass = (currTransition.loop) ? currTransition.loop : 1
			
			draw(data)			
			setClickArea()
			ready = true			
			// call custom text updated used by extenders
			textUpdated()
		}
		
		// do nothing
		protected function textUpdated() {
		}
		
		// this will update transitions
		public function updateTransition() {
		
			// reset timer
			tim.reset()
			
			if (currTransitionIdx < conf.transition.length) {
				currTransitionIdx++
			} else {
				// last transition 
				if (conf.noloop) {
					// noloop mode, destroy
					return destroy()
				} else {
					// loop mode, start from first
					currTransitionIdx = 1
				}
			}
			
			
			
			currTransition = conf.transition[currTransitionIdx-1]
			
			// set font
			setFont(currTransition.font,currTransition.size)
			
			// set color, if defined
			if (currTransition.color) buildColorMap(currTransition.color)
			
			currTextIdx = 0
			
			// used by extenders
			transitionUpdated()
			
			// update text
			updateText(true)
			
		}
		
		// destructor
		protected function destroy() {
			// remove event listeners
			tim.removeEventListener(TimerEvent.TIMER, updateText);
			if (conf.centered) {
				stage.removeEventListener(Event.RESIZE,layout)
			}
			// remove the instance
			parent.removeChild(this)
		}
		
		// remove the effect
		public function remove() {
			destroy()
		}
		
		// do nothing
		protected function transitionUpdated() {
		}
		
		// this will parse xml configuration
		public function configure(xmlConf,id=null,url=null) {
			conf=xmlParser.toObject(xmlConf)
			
			if (stage) {
				// if stage exist, init
				init()
			} else {
				// otherways, wait until item is added
				addEventListener(Event.ADDED_TO_STAGE,init)
			}
		}
		
		// helper: convert hex color to object (used internally)
		private function hex2rgb(hex) {
			return {
				a:hex >>> 24,
				r:hex >>> 16 & 0xff,
				g:hex >>> 8 & 0xff, 
				b:hex & 0xff 
			}
		}
		
		// build gradient based on preset or custom colors
		public function buildColorMap(c = "ocean") {
		
			if (c is String) {
				c = gradients[c]
				if (!c) c=gradients.ocean
			} else if (c is uint) {
				if (c < 0x01000000) {
					c=[0,0xFF000000 | c ]
				} else {
					c=[0,c]
				}
			} 
			
			// we have c.length colors
			// final gradient will have 256 values (0xFF) 
			
			var idx=0;
			
			// number of sub gradients = number of colors - 1
			var ng=c.length-1
			
			// each sub gradient has 256/ng values
			var step=256/ng;
			
			var cur:Object,next:Object;
			var rs:Number,gs:Number,bs:Number,al:Number,color:uint
			
			// for each sub gradient
			for (var g=0;g<ng;g++) {
				// we compute the difference between 2 colors 
			
				// current color
				cur = hex2rgb(c[g])
				// next color
				next = hex2rgb(c[g+1])
				
				// RED delta
				rs = (next.r-cur.r)/(step)
				// GREEN delta
				gs = (next.g-cur.g)/(step)
				// BLUE delta
				bs = (next.b-cur.b)/(step)
				// ALPHA delta
				al = (next.a-cur.a)/(step)
				
				// compute each value of the sub gradient
				for (var i=0;i<=step;i++) {
					colorMap[idx] = cur.a << 24 | cur.r << 16 | cur.g << 8 | cur.b;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
		}
			
	}

}
	