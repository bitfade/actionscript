/*

	This class is used to play videos

*/
package bitfade.media.players {
	
	import flash.net.*
	import flash.media.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.geom.*
	import flash.text.*
	import flash.utils.*
	import flash.ui.Mouse
	
	import bitfade.core.*	
	import bitfade.ui.*
	import bitfade.ui.icons.*
	import bitfade.ui.core.*
	import bitfade.ui.spinners.*
	import bitfade.ui.backgrounds.engines.Caption
	import bitfade.ui.frames.*
	import bitfade.ui.text.TextField
	import bitfade.utils.*
	import bitfade.media.*
	import bitfade.media.visuals.*
	import bitfade.media.streams.*
	import bitfade.easing.*
	
	public class Player extends Sprite implements bitfade.core.IBootable,bitfade.core.IResizable,bitfade.core.IDestroyable {
	
		public var configName:String = "player"
	
		/*
			config defaults, NO EDIT HERE !
			use flashVars or xml to override
			
			all parameters explained in help file
		*/
		public var defaults:Object = {
			
			width: 0,
			height: 0,
			
			start: {
				resource: "",
				cover: "",
				caption: "",
				paused: true,
				buffering: false,
				zoom: "fillmax",
				volume: 0.8
			},
			
			advertise: {
				resource: "",
				caption: "",
				disableSeek: true,
				disablePause: true,
				playing: false,
				done: false
			},
			
			watermark: {
				resource: "",
				alpha: 0.3,
				align: "top,right",
				zoom: "fit",
				width: 0,
				height: 0
			},
			
			description: {
				show: "over",
				height: 85,
				hideAfter: 2,
				showAfter: 0.5,
				onCover: true,
				
				// internal use
				visible: false,
				mouseOver: false,
				delay: 0
			},
			
			fullscreen: {
				type: "full",
				onTop: false,
				hideCursor: 0,
				resizable: true,
				zoom: "fitmax",
				zoomOnExit: "fillmax",
				width: 0,
				height: 0,
				marginTop: 0,
				marginRight: 0,
				marginBottom: 0,
				marginLeft: 0
			},
			
			playback: {
				onStop: "cover",
				type: "video",
				bufferTimeMax: 10
			},
			
			controls: {
				show: "always",
				alpha: 1,
				blendMode: "normal",
				play: true,
				bar: true,
				time: true,
				volume: true,
				fullscreen: true,
				zoom: true
			},
			
			style: {
				transparent: 0,
				global: "dark",
				text: <style><![CDATA[
					title {
						colorDark: #FFD209;
						colorLight: #466FB9;
						font-family: Sapir Sans;
						font-size: 20px;
						text-align: left;
					}
					description {
						colorDark: #FFFFFF;
						colorLight: #505050;
						font-family: Sapir Sans;
						font-size: 13px;
						text-align: left;
					}
					em {
						colorDark: #FFDF6E;
						colorLight: #466FB9;
						font-size: 13px;
						display: inline;
					}
				]]></style>.toString(),
				barType: "",
				barColor1: -1,
				barColor2: -1,
				barColor3: -1,
				barColor4: -1,
				
				iconType: "",
				iconColor: -1,
				iconOverColor: -1,
				
				pbarType: "",
				pbarColor1: -1,
				pbarColor2: -1,
				pbarColor3: -1,
				pbarColor4: -1,
				pbarColor5: -1,
				pbarColor6: -1,
				pbarColor7: -1,
				pbarColor8: -1,
				pbarColor9: -1
				
			},
			
			external: {
				font: "resources/fonts/Sapir.swf",
				buttonsFont: "resources/fonts/TempestaSevenCondensedBold.swf"
			},
			
			events: {
				streamEvents: false,
				playerEvents: true
			},
			
			saved : {
			}
		} 
		
		// holds the configuration
		public var conf:Object
		// external resource url
		protected var resource:String
		// main window
		protected var frame:bitfade.ui.Empty
		// visualizer
		protected var vid:bitfade.media.visuals.Visual
		
		// playback controls	container
		protected var controls:Sprite;
		// cover and main play icon container
		protected var onTop:Sprite;
		// holds cover
		protected var coverOnTop:Bitmap;
		// holds watermark
		protected var watermark:DisplayObject;
		// holds description
		protected var description:Sprite;
		// play icon
		protected var playOnTop:bitfade.ui.icons.BevelGlow;
		// controls background 		
		protected var backgroundBar:flash.display.Shape;
		// playback controls		
		protected var seekBar:bitfade.ui.Slider;
		protected var volumeBar:bitfade.ui.Slider;
		protected var dragControl:bitfade.ui.Empty;
		protected var playControl:bitfade.ui.icons.BevelGlow
		protected var pauseControl:bitfade.ui.icons.BevelGlow
		protected var volumeControl:bitfade.ui.icons.BevelGlow
		protected var zoomControl:bitfade.ui.icons.BevelGlow
		protected var fsControl:bitfade.ui.icons.BevelGlow
		
		// text caption
		protected var timeCaption: bitfade.ui.text.TextField;
		protected var statusCaption: bitfade.ui.text.TextField;
		protected var zoomCaption: bitfade.ui.text.TextField;
		protected var descriptionCaption: bitfade.ui.text.TextField
		
		// tween for description
		protected var descriptionTw:*
		// tween for controls
		protected var controlsTw:*
		// tween for cover
		protected var coverTw:*
		
		// stream controller
		protected var controlStream:Stream
		
		// dragging status codes
		protected const NONE:uint = 0
		protected const SEEK:uint = 1
		protected const VOLUME:uint = 2
		
		// dragging status
		protected var _dragging:uint = NONE
		
		// some needed boolean
		public var isFullScreen:Boolean = false
		protected var resumeOnSeekEnd:Boolean = true
		protected var muted:Boolean = false;
		protected var coverLoading:Boolean = false;
		protected var immediateStart:Boolean = false;
		
		// loading spinner
		protected var spinner:bitfade.ui.spinners.Circle
		
		// this are used to fade in/out controls on mouse over
		protected var mouseOver:Boolean
		protected var moveCounter:uint = 0
		
		// player dimentions
		protected var w:uint = 0
		protected var h:uint = 0
		
		// constructor
		public function Player(...args) {
			super()
			// boot the player
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// this gets called on ADDED_TO_STAGE
		public function boot(...args):void {
			// parse config
			Config.parse(this,init,args)
		}
		
		// init player
		protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			
			if (xmlConf) {
				// override with xml conf
				conf = Misc.setDefaults(XmlParser.toObject(xmlConf),conf)
			}
			
			// set dimentions
			w = conf.saved.w = !conf.fullscreen.resizable && conf.width > 0 ? conf.width : stage.stageWidth
			h = conf.saved.h = !conf.fullscreen.resizable && conf.height > 0 ? conf.height : stage.stageHeight
			
			
			
			loadExternalResources()
						
		}
		
		// load external resources
		protected function loadExternalResources():void {
			
			var extUrl:String
			var resources:Array = []
			
			for (var name:String in conf.external) {
				extUrl = conf.external[name]
				extUrl = name.match(/font/i)  ? "font|"+extUrl : extUrl
				resources.push(extUrl)
			}
			
			if (resources.length > 0) {
			
				spinner = new bitfade.ui.spinners.Circle()
				spinner.x = (w-spinner.width)/2
				spinner.y = (h-spinner.height)/2
				
				addChild(spinner)
				spinner.show()
				
				// load external resources 
				ResLoader.load(resources,externalResourcesLoaded)
				
			} else {
				// init display
				initDisplay()
			}
		}
		
		// gets called when external resources are loaded
		protected function externalResourcesLoaded(resources:*,id:*=null,url:*=null):void {
			initDisplay()
		}
		
		protected function setGlobalStyle() {
		
			var sTokens:Array = conf.style.global.split(/\./);
			
			conf.style.type = sTokens[0]
			conf.style.scheme = sTokens[1]
			
		
		}
		
		// init display
		protected function initDisplay():void {
			
			setGlobalStyle()
			
			// create main visualizer
			frame = new bitfade.ui.Empty(w,h,true,conf.style.type == "dark" ? 0x000000 : 0xFFFFFF);
			frame.name = "visualizer"
			frame.buttonMode = false
			addChild(frame)
			
			// set visuals
			setVisual()
			
			// create onTop layer
			onTop = new Sprite();
			onTop.name = "visualizer"
			addChild(onTop)
			
			// draw onTop layer
			drawOnTop()
			
			// create controls
			controls = new Sprite();
			addChild(controls)
			controlsTw = Tw.to(controls, .5, {}, {ease:Cubic.Out});
			coverTw = Tw.to(coverOnTop, .5, {}, {ease:Cubic.Out});
			
			// add controls
			drawControls()
			
			fireEvent(PlayerEvent.READY,getTimer())
			
			if (conf.watermark.resource) {
				ResLoader.load(conf.watermark.resource,watermarkLoaded)	
			}
			
			startPlayer()
			
		}
		
		// load first resource
		protected function startPlayer() {
			// if resource defined in conf, load it
			if (conf.advertise.resource) {
				// too much trouble for handling conf.advertise.caption, so disabling for now
				//load(conf.advertise.resource,conf.start.cover,conf.advertise.caption)
				load(conf.advertise.resource,conf.start.cover,conf.start.caption)
			} else if (conf.start.resource) {
				load(conf.start.resource,conf.start.cover,conf.start.caption)
			}
		}
		
		// set visualizer
		protected function setVisual():void {
			if (frame && controlStream && controlStream.ready) {
				
				// if we have a visualizer, remove it
				if (vid) {
					vid.destroy()
					//frame.removeChild(vid)
				}
				// create a new one
				createVisual()
				vid.zoom(conf.start.zoom)
				// link it to stream and add to its holder
				vid.link(controlStream)
				frame.addChild(vid)
				
				/*
				// FIX FOR YOUTUBE GOOGLE ADDS
				onTop.mouseEnabled = false
				vid.mouseEnabled = true
				vid.mouseChildren = true
				if (description) {
					description.mouseEnabled = false
				}
				*/
			}
			
		}
		
		protected function getVisualClass():String {
			return "bitfade.media.visuals.Video";
		}
		
		protected function get visualHeight():Number {
			return (conf.controls.show == "always") ? h-Math.floor(controls.height) : h
		}
		
		// create visualizer
		protected function createVisual():void {
			var visualClass:Class = Class(getDefinitionByName(getVisualClass()));
			vid = new visualClass(w,visualHeight)
		}
		
		
		// draw on top layer
		protected function drawOnTop():void {
		
			// new
			bitfade.ui.icons.BevelGlow.setStyle(conf.style.type)
			
			// create play icon
			playOnTop = new bitfade.ui.icons.BevelGlow("play","play",48)
			playOnTop.blendMode = "hardlight"
			
			playOnTop.alpha = 1
			playOnTop.visible = false
			
			// create cover holder
			coverOnTop = new Bitmap()
			
			// create the spinner
			if (!spinner) spinner = new bitfade.ui.spinners.Circle()
			
			drawDescription()
			
			onTop.addChild(coverOnTop)
			onTop.addChild(description)
			onTop.addChild(spinner)
			onTop.addChild(playOnTop)
		
		}
		
		// draws controls
		protected function drawControls():void {
			
			var customColors:Array
			
			switch (conf.style.scheme) {
				case "ocean":
					customColors = conf.style.scheme == "dark" ? [0x2983C1,0x9DE5FF,0x2480BF,0xCEF2FF] : [0x337CFE,0x327FC5,0x193FA5,0x6F7FAE]
				break;
				case "lime":
					customColors = conf.style.scheme == "dark" ? [0x29C197,0x81F8EF,0x29C1B5,0x81F8EF] : [0x036A58,0x288E7B,0x056151,0x3B7D72]
				break;
				case "mono":
					customColors = conf.style.scheme == "dark" ? [0x707070,0xF0F0F0,0xD8D8D8,0xB0B0B0] : [0x707070,0x808080,0x606060,0x3B3B3B]
				break;
			}
			
			if (customColors) {
				
				conf.style.iconOverColor = customColors[0]
				/*
				style.pbarColor7 = customColors[1]
				style.pbarColor8 = customColors[2]
				style.pbarColor9 = customColors[3]
				*/
		
			}
			
			var darkColorScheme:Boolean = conf.style.type == "dark"
			
			//backgroundBar = bitfade.ui.bars.shape.create(style.barType,w,24,[style.barColor1,style.barColor2,style.barColor3,style.barColor4])
			//backgroundBar = bitfade.ui.frames.shape.create("default.dark",w,24,0,0,null,null,0)
			// background bar
			
			backgroundBar = bitfade.ui.frames.Shape.create("default."+conf.style.type,w,24,0,0,null,null,0)
			
			controls.addChild(backgroundBar)
			
			// set icons/slider style
			bitfade.ui.icons.BevelGlow.setStyle(conf.style.type,[conf.style.iconColor,conf.style.iconOverColor])
			Slider.setStyle(conf.style.type)
			
			// set progress bar style
			with (conf.style) {
				Slider.setStyle(conf.style.type,[pbarColor1,pbarColor2,pbarColor3,pbarColor4,pbarColor5,pbarColor6,pbarColor7,pbarColor8,pbarColor9])
			}
			
			if (conf.controls.play) {
				// playback controls
				playControl = new bitfade.ui.icons.BevelGlow("play","play")
				playControl.visible = false;
				pauseControl = new bitfade.ui.icons.BevelGlow("pause","pause")
					
				controls.addChild(playControl)
				controls.addChild(pauseControl)
			}
			
  			if (conf.controls.fullscreen) {
  				fsControl = new bitfade.ui.icons.BevelGlow("fullscreen","fullscreen")
  				controls.addChild(fsControl)
  			}
  			
  			if (conf.controls.bar) {
  				// seek bar
				seekBar = new bitfade.ui.Slider(100,24,6)
			 	
			 	// status caption
				statusCaption = new bitfade.ui.text.TextField({
					defaultTextFormat: new TextFormat("Verdana",7,darkColorScheme ? 0xFFFFFF : 0,true,null,null,null,null,"left"),
					mouseEnabled:false,
					scrollRect: new Rectangle(0,3,60,8),
					filters: [
						new DropShadowFilter(1,45,darkColorScheme ? 0 : 0xFFFFFF,.7,1,1,1,1),
						new DropShadowFilter(1,-45,darkColorScheme ? 0 : 0xFFFFFF,.7,1,1,1,1)
					]
				})
				
				seekBar.name = "seek"
			
  				controls.addChild(seekBar)
  				controls.addChild(statusCaption)
  			}
  			
  			if (conf.controls.time) {
  				// time caption
  				timeCaption = new bitfade.ui.text.TextField({
					name: "time",
					defaultTextFormat: new TextFormat("Tahoma",9,darkColorScheme ? 0xFFFFFF: 0,null,null,null,null,null,"right"),
					mouseEnabled: false,
					width: 60,
					filters: [
						new DropShadowFilter(1,45,darkColorScheme ? 0 : 0xFFFFFF,1,1,1,1,1)
					]
				})
				
				updateTimeCaption()
				
  				controls.addChild(timeCaption)
  			}
  			
  			if (conf.controls.zoom) {
  				zoomControl = new bitfade.ui.icons.BevelGlow("zoom","zoom",16,35)
  			
  				// zoom caption
				zoomCaption = new bitfade.ui.text.TextField({
					defaultTextFormat: new TextFormat("Arial Black",7,darkColorScheme ? 0xB0B0B0 : 0x404040,false,null,null,null,null,"center"),
					width: 24,
					scrollRect: new Rectangle(0,3,24,8),
					mouseEnabled: false,
					blendMode: "layer"		
				})
				
				setZoom(conf.start.zoom)
				
				controls.addChild(zoomControl)
  				controls.addChild(zoomCaption)
  				
  			}
  			
  			if (conf.controls.volume) {
  				// mute / unmude
  				volumeControl = new bitfade.ui.icons.BevelGlow("volume","volume")
  					
  				// volume bar
				volumeBar = new bitfade.ui.Slider(30,24,6)
				volume(conf.start.volume)
				
  				volumeBar.name = "volumeBar"
			
  				controls.addChild(volumeBar)
  				controls.addChild(volumeControl)
  			}
  			
  			dragControl = new bitfade.ui.Empty(100,100)
  			
			name = "player"
			controls.name = "controls"
			dragControl.name = "drag"
			
			addChild(dragControl)
						
			drawCustomControls()
						
			// add listeners 
			with (bitfade.utils.Events) {
				add(dragControl,MouseEvent.MOUSE_MOVE,evHandler,this)
				add(this,[
					MouseEvent.MOUSE_OVER,
					MouseEvent.MOUSE_OUT,
					MouseEvent.ROLL_OUT,
					MouseEvent.MOUSE_UP,
					MouseEvent.MOUSE_DOWN,
					MouseEvent.MOUSE_WHEEL,
					Event.ENTER_FRAME
				],evHandler)
				
				if (conf.fullscreen.hideCursor) add(this,MouseEvent.MOUSE_MOVE,evHandler)
				
				if (conf.fullscreen.type == "full") add(stage,Event.RESIZE,resizeHandler,this)
			}
			
			// call resize to adjust position
  			resize()
  			showPlayOnTop()
		}
		
		protected function drawCustomControls():void {
		}
		
		// set default style colors
		protected function setStyleColors(style:String):String {
			if (conf.style.type == "light") {
				style = style.replace(/colorLight:/g,"color:")
				style = style.replace(/colorDark: .*/g,"")
			} else {
				style = style.replace(/colorDark:/g,"color:")
				style = style.replace(/colorLight: .*/g,"")
			}
			return style
		}
		
		// draw description
		protected function drawDescription() {
			
			// create description holder
			description = new Sprite()
			description.alpha = 0
			description.name = "description"
			
			// create description background
			var backBitmap = new Bitmap()
			
			
			description.addChild(backBitmap)
			var darkColorScheme:Boolean = conf.style.type == "dark"
			
			descriptionCaption = new bitfade.ui.text.TextField({
				name:		"description",
				styleSheet:	setStyleColors(conf.style.text is String ? conf.style.text : conf.style.text.content),
				width: 		w,
				thickness:	darkColorScheme ? -100 : 50,
				sharpness:  darkColorScheme ? 0 : -100,
				filters:	[
					new DropShadowFilter(1,45,darkColorScheme ? 0 : 0xFFFFFF,1,2,2,1),
				]
			})
			
			/*
			if (conf.external.font == "") {
				descriptionCaption.thickness += 300
				descriptionCaption.sharpness -= 300
			}
			*/
			
			descriptionTw = Tw.to(description, 0.5, {}, {ease:Cubic.Out,delay:100,onComplete:hideDescription});
			
			description.addChild(descriptionCaption)
			
		}
		
		// resize elements
		public function resize(nw:uint = 0,nh:uint = 0):void {
			if (!conf) return
			
			// set new size (if needed)
			if (nw > 0) w = nw
			if (nh > 0) h = nh
			
			spinner.x = (w-spinner.width)/2
			spinner.y = (h-spinner.height)/2
			
			
			resizeControls()
			resizeVisual()
			resizeCover()
			resizeWatermark()
			resizeDescription()
		}
		
		protected function resizeControls():void {
			
			controls.blendMode = conf.controls.blendMode
			controls.visible = (conf.controls.show != "never")
			controls.alpha = conf.controls.show == "always" ? 1 : 0
			
			// mask the whole thing to new dimentions
			scrollRect = new Rectangle(0,0,w,h)
			
			// no much to be said here, just some offset math
			// to position controls
			var leftMargin:Number = 0
			var rightMargin:Number = w
			var pad:Number = 4
			
			controls.y = h - 24
			
			playOnTop.x = (w-playOnTop.width)/2
			playOnTop.y = (h-playOnTop.height)/2
			
			backgroundBar.width = w
			backgroundBar.height = 24
			
			frame.resize(w,h)
			dragControl.resize(w,h)
			
			if (conf.controls.play) {
				playControl.x = 4
				playControl.y = 4
		
				pauseControl.x = 3
  				pauseControl.y = 4
  				
  				leftMargin += (playControl.width+pad*2)
			}
			
			if (conf.controls.zoom) {
				rightMargin = zoomControl.x = rightMargin-zoomControl.width-pad
  				zoomControl.y = 4
			
				zoomCaption.x = zoomControl.x + 11
				zoomCaption.y = zoomControl.y + 4	
			}
			
			if (conf.controls.fullscreen) {
				rightMargin = fsControl.x = rightMargin-fsControl.width-pad+(conf.controls.zoom ? 4 : 0)
  				fsControl.y = 4
			}
			
			if (conf.controls.volume) {
				rightMargin = volumeBar.x = rightMargin-volumeBar.width-(rightMargin == w ? pad : uint(pad*1.5+.5))	
				volumeBar.y = 0
				rightMargin = volumeControl.x = rightMargin-volumeControl.width-pad				
				volumeControl.y = 4

			}
			
			if (conf.controls.time) {
				rightMargin = timeCaption.x = rightMargin-timeCaption.width-pad				
				timeCaption.y = 4
			} else {
				rightMargin -= (pad*2)
			}
			
			if (conf.controls.bar) {
				rightMargin -= (rightMargin == w) ? 8 : 0
				leftMargin += (leftMargin == 0) ? 8 : 0
			
				statusCaption.width = seekBar.width = rightMargin - leftMargin
				seekBar.x = statusCaption.x = leftMargin
				statusCaption.y = 1
				statusCaption.x -= 2
				statusCaption.scrollRect = new Rectangle(0,3,seekBar.width,8)
			}

		}
		
		protected function resizeVisual() {
				
			if (vid) {
				vid.zoom(conf.start.zoom)
				vid.resize(w,visualHeight)
			}
		}
		
		// update progress bar
		protected function updateBar(e:StreamEvent):void {
			if (conf.events.streamEvents) dispatchEvent(e)
			if (conf.controls.bar) {
				switch (e.type) {
					case StreamEvent.START_POS:
						seekBar.start(e.value)
					break;
					case StreamEvent.PROGRESS:
						seekBar.pos(e.value)
					break;
					case StreamEvent.POSITION:
						if (dragging != SEEK) {
							seekBar.pos(-1,e.value)
						}
					break;
				}
			}
			updateTimeCaption();
		}
		
		// update time caption
		protected function updateTimeCaption():void {
			if (!conf.controls.time) return
			timeCaption.htmlText = controlStream ? convertTime(controlStream.time) + " / " + convertTime(controlStream.duration) : "0:00 / 0:00"
		}
		
		// convert time from number to string
		protected function convertTime(t:Number):String {
			var ts:String = ""
			var v:Number 
			v = Math.round(t) % 60;
			ts = (v < 10 ? "0" : "") +v 
			v = Math.floor(t / 60)
			ts = v + ":" + ts
			return ts;
		}
		
		// show a message to status caption
		protected function showMessage(msg:String=""):void {
			if (conf.controls.bar) statusCaption.htmlText = msg.toUpperCase()
		}
		
		// set description message
		public function setDescription(msg:String=null):void {
			descriptionCaption.content(msg)
			if (msg) {
				descriptionCaption.x = int((w-descriptionCaption.width)/2)
				showDescription(true,conf.description.hideAfter)				
			}
		}
		
		// hide description
		protected function hideDescription(tw:* = null) {
			showDescription(false)
		}
		
		// show/hide description
		public function showDescription(show:Boolean = true,delay:Number = 0):void {
			
			var descConf = conf.description
			
			if (descConf.show == "never") {
				descriptionCaption.visible = false
				return
			}
			
			if (show) {
				
				descConf.delay = delay
				if (descriptionCaption.htmlText == "" || descConf.visible || (coverOnTop.visible && !descConf.onCover) ) return
				
				descConf.visible = true
				
				descriptionTw.onComplete = delay > 0 ? hideDescription : null
				descriptionTw.proxy.alpha = 1
				descriptionTw.position = (coverOnTop.visible || delay > 0) ? 0 : -descConf.showAfter
				
			} else {
				
				if (!descConf.visible || descConf.show == "always") return
				
				if (descConf.onCover) {
					if (descConf.mouseOver || coverOnTop.visible) return
				} else {
					if (descConf.mouseOver && !coverOnTop.visible) return
				}
				
				if (description.alpha == 0) {
					// we need to hide but alpha is already 0, so we just reset tween animation
					descriptionTw.proxy.alpha = 0
					descriptionTw.end()
					descConf.visible = false
				} else if (descriptionTw.paused) {
					// set up tween for fade out
					descriptionTw.proxy.alpha = 0
					descriptionTw.position = -descConf.delay
					descConf.visible = false
				} else {
					// tween is running, set up fade out when it completes
					descriptionTw.onComplete = hideDescription
				}
				
			}
		}
		
		protected function getStreamClass():String {
			return Stream.getClassFrom(conf.playback.type,resource)
		}
		
		// create control stream
		protected function createStream():void {
		
			if (controlStream) controlStream.destroy()
			
			var streamClass:Class = Class(getDefinitionByName(getStreamClass()));
			
			controlStream = new streamClass()
			
			// add event listeners
			with (bitfade.utils.Events) {
				add(controlStream,StreamEvent.GROUP_PROGRESS,updateBar,this)
				add(controlStream,StreamEvent.GROUP_PLAYBACK,streamEventHandler,this)
			}
			
		}
		
		// load a movie 
		public function load(...args):void {
			
			
			if (!conf) return
			
			var url:String = args[0] 
			var image:String= args[1]
			
			
			immediateStart = conf.advertise.playing
			
			/*
			
					CHECK THIS!
					|||||||||||
					VVVVVVVVVV
			
			*/
			if (!immediateStart) immediateStart = !conf.start.paused
			/*
			
					END CHECK
				
			*/
			
			if (args[3] == true) immediateStart = true
			
			
			
			setDescription(args[2] is String ? args[2] : (args[2] is Object ? args[2].content: null))
			
			// if we have cover, load it
			if (image) cover(image)
			
			resource = url
			
			conf.advertise.playing = (resource != "" && resource == conf.advertise.resource)
		
			// create the stream
			createStream()
			
			// load movie into stream
			controlStream.load(url,immediateStart ? false : conf.start.paused,immediateStart ? true : conf.start.buffering)
			
			// set volume
			controlStream.volume(muted ? 0 : conf.start.volume)
			// set max buffer time
			controlStream.bufferTimeMax = conf.playback.bufferTimeMax
			
			// set visuals
			
			if (controlStream.ready) {
				setVisual()
			} 
			
			// reset progress bar
			if (conf.controls.bar) {
				seekBar.start(0)
				seekBar.pos(0,0)
			}
		}
				
		// load a cover
		public function cover(url:String):void {
			if (!conf || !url) return
			coverLoading = true
			spinner.show(0.1)
			coverTw.proxy.alpha = 0
			conf.start.paused = true
			ResLoader.load(url,coverLoaded)
			showCoverOnTop()
			showPlayOnTop()
		}
		
		// gets called when cover is loaded
		protected function coverLoaded(image:*,id:*=null,url:*=null):void {
			coverLoading = false
			if (controlStream && controlStream.ready) spinner.hide()
			//spinner.hide()
			// remove old cover
			if (coverOnTop.bitmapData) coverOnTop.bitmapData.dispose()
			if (!image) return
			// set new one
			coverOnTop.bitmapData = image.bitmapData
			coverTw.proxy.alpha = 1
			resizeCover()
			showCoverOnTop()
			showPlayOnTop()
		}
		
		// gets called when watermark is loaded
		protected function watermarkLoaded(wmark:*):void {
			
			if (!wmark) return
			
			var wconf = conf.watermark
			
			watermark = wmark
			watermark.alpha = 0
			
			// scale watermark if needed
			if (wconf.width > 0 && wconf.height > 0 ) {
			
				var scaler:Object = Geom.getScaler(wconf.zoom,"center","center",wconf.width,wconf.height,wmark.width,wmark.height)
				
				try {
					wmark.smoothing = true
				} catch (e:*) {}
				
				// apply new scale value
				watermark.scaleX = watermark.scaleY = scaler.ratio
				
			}
			
			resizeWatermark()
			watermark.alpha = 0
			onTop.addChild(watermark)
			Tw.to(watermark, 1, {alpha:wconf.alpha}, {ease:Cubic.Out});
		}
		
		protected function resizeWatermark():void {
			if (!watermark) return
		
			var align:Object = Geom.splitProps(conf.watermark.align)
			var scaler:Object = Geom.getScaler("none",align.w,align.h,w,h-24,watermark.width,watermark.height)
			
			watermark.x = scaler.offset.w
			watermark.y = scaler.offset.h
		
		}
		
		protected function resizeDescription():void {
			
			
			// update description background
			Snapshot.take(bitfade.ui.backgrounds.engines.Caption.create(conf.style.type,w,conf.description.height),Bitmap(description.getChildAt(0)))
			
			descriptionCaption.maxWidth = w-10
			descriptionCaption.maxHeight = conf.controls.show == "always" ? conf.description.height - Math.floor(controls.height) : conf.description.height
			
			setDescription()			
			descriptionCaption.x = int((w-descriptionCaption.width)/2)
			description.y = h-conf.description.height 
		}
		
		// set dragging mode
		protected function set dragging(d:uint):void {
			_dragging = d
			dragControl.visible = _dragging != NONE
		} 
		
		// get dragging mode
		protected function get dragging():uint {
			return _dragging
		}
		
		// resize cover
		protected function resizeCover():void {
			if (!coverOnTop.bitmapData) return
			// get the scaler
			var scaler:Object = Geom.getScaler("fillmax","center","center",w,h,coverOnTop.bitmapData.width,coverOnTop.bitmapData.height)
			
			// apply new scale value / offsets
			coverOnTop.smoothing = true
			coverOnTop.scaleX = coverOnTop.scaleY = scaler.ratio
			
			coverOnTop.x = scaler.offset.w
			coverOnTop.y = scaler.offset.h	
		}
		
		// show / hide cover image
		protected function showCoverOnTop(forceVisible:Boolean = false):void {
			if (coverLoading || !coverOnTop.bitmapData) {
				// check this 
				if (!coverOnTop.bitmapData) {
					coverOnTop.visible = false
				}
			} else {
				coverOnTop.visible = (!immediateStart && !controlStream.playStarted) || (conf.playback.onStop == "cover" && (forceVisible || controlStream.stopped))
			}
			
			// handle description visibility
			if (conf.description.onCover) {
				if (coverOnTop.visible) {
					showDescription()
				}
			} else if (coverOnTop.visible) {
				hideDescription()
			}
			
		}
		
		// show / hide play icon
		protected function showPlayOnTop():void {
		
			var isPaused:Boolean,isBuffering:Boolean
			
			if (controlStream) {
				isPaused = controlStream.paused || controlStream.stopped || (!immediateStart && !controlStream.playStarted)
				isBuffering = controlStream.buffering				
			} else {
				isPaused = true 
				isBuffering = false
			}
			
			playOnTop.visible = !spinner.visible && (!isBuffering && isPaused && !(dragging == SEEK && resumeOnSeekEnd))
			
			if (conf.controls.play) {
				playControl.visible = playOnTop.visible
				pauseControl.visible = !playControl.visible
			}			
		}
		
		// helper, return a value in the 0 - 1 range 
		public static function range01(v:Number):Number {
			return v > 1 ? 1 : (v < 0 ? 0 : v)
		}
			
		// pause playback
		public function pause():void {
			if (conf.advertise.playing && conf.advertise.disablePause) return
			if (controlStream && controlStream.pause()) {
				if (vid) vid.pause()
				fireEvent(PlayerEvent.PAUSE)
			}
		}
		
		// resume playback
		public function resume():void {
			if (controlStream && controlStream.resume()) {
				if (vid) vid.resume()
				fireEvent(PlayerEvent.PLAY)
			}
		}
		
		// play is alias of resume
		public function play():void {
			resume()
		}
		
		// stop playback
		public function stop():void {
			if (controlStream) controlStream.stop();
		}
		
		// toggle pause / play
		public function toggle():void {
			if (controlStream && controlStream.paused) {
				resume()
			} else {
				pause()
			}
		}
		
		// seek playback
		public function seek(pos:Number):void {
			if (controlStream) {
				// to be checked
				if (!controlStream.playStarted) return resume()
				
				if (conf.advertise.playing && conf.advertise.disableSeek) return
				
				pos = range01(pos)
				if (pos != controlStream.position) {
					
					pos = controlStream.seek(pos,dragging != SEEK)
			
					if (conf.controls.bar) seekBar.pos(-1,pos)
					showCoverOnTop(pos == 1)
				}
				fireEvent(PlayerEvent.SEEK,pos*controlStream.duration)
			}
		}
		
		// set volume
		public function volume(vol:Number,save:Boolean = true):void {
			vol = range01(vol)
			if (vol < 0.1) {
				vol = 0
				muted = true
			} else {
				muted = false
			}
			volumeBar.pos(1,vol)
			if (controlStream) controlStream.volume(vol)
			if (save) conf.start.volume = vol
			fireEvent(PlayerEvent.VOLUME,muted ? 0 : uint(vol*100+.5)/100)
		}
		
		// set zoom mode
		public function setZoom(mode:String):void {
			if (conf.controls.zoom) {
				switch (mode) {
					case "fillmax":
						zoomCaption.htmlText = "FILL"
					break;
					case "fitmax":
						zoomCaption.htmlText = "FIT"
					break;
					default:
						mode = "none"
						zoomCaption.htmlText = "1 : 1"
					break;
				}
			}
			conf.start.zoom = mode
			fireEvent(PlayerEvent.ZOOM,mode == "none" ? 1 : (mode == "fillmax" ? 2 : 3))
			resizeVisual()
		}
		
		// cycles trought zoom modes
		public function switchZoom():void {
			switch (conf.start.zoom) {
				case "none":
					setZoom("fillmax")
				break;
				case "fillmax":
					setZoom("fitmax")
				break;
				case "fitmax":
					setZoom("none")
				break;
			}
		}
		
		// set fullscreen mode
		public function setFullScreen(fs:Boolean):void {
			
			var nw:Number,nh:Number
			
			if (fs) {
				// set up fullscreen
				// save position
				conf.saved.x = x
				conf.saved.y = y
				
				// if player is resizable
				if (conf.fullscreen.resizable) {
					// save current dimentions
					conf.saved.w = w
					conf.saved.h = h
				}
				
				// if we need to go on top
				if (conf.fullscreen.onTop) {
					// save player position on display list
					conf.saved.parent = parent
					conf.saved.childIndex = parent.getChildIndex(this)
					// let's go on top of the world
					stage.addChild(this)
				}
				
				// set zoom
				setZoom(conf.fullscreen.zoom)
				
				if (conf.fullscreen.type == "full") {
					
					// full fullscreen mode
					if (stage.displayState != StageDisplayState.FULL_SCREEN) {
						stage.displayState = StageDisplayState.FULL_SCREEN
					}
					
					x = conf.fullscreen.marginLeft
					y = conf.fullscreen.marginTop
					
					nw = stage.stageWidth - conf.fullscreen.marginLeft - conf.fullscreen.marginRight
					nh = stage.stageHeight - conf.fullscreen.marginTop - conf.fullscreen.marginBottom
										
				} else {
					// fixed fullscreen mode
					nw = conf.fullscreen.width > 0 ? conf.fullscreen.width : w*1.2
					nh = conf.fullscreen.height > 0 ? conf.fullscreen.width : h*1.2
				}
				// resize the player
				resize(nw,nh)
				
			} else {
				
				if (conf.fullscreen.hideCursor) Mouse.show()
				
				// exit from fullscreen
				// restore position
				x = conf.saved.x
				y = conf.saved.y
				
				// restore position on display list
				if (conf.fullscreen.onTop) conf.saved.parent.addChildAt(this,conf.saved.childIndex)
				
				// set display state (if needed)
				if (conf.fullscreen.type == "full" && stage.displayState != StageDisplayState.NORMAL) stage.displayState = StageDisplayState.NORMAL;
				
				// set zoom and resize
				setZoom(conf.fullscreen.zoomOnExit)
				resize(conf.saved.w,conf.saved.h)
				
				if (conf.fullscreen.type == "full") {
					/*
						we fire	an extra Event.RESIZE event *after* resizing the player
						so that, if we have an application listening to Event.RESIZE which also
						resizes player, his method gets called after resizeHandler
					
					*/
					stage.removeEventListener(Event.RESIZE,resizeHandler)
					stage.dispatchEvent(new Event(Event.RESIZE))
					stage.addEventListener(Event.RESIZE,resizeHandler)
				}
			}
			isFullScreen = fs
		}
		
		// cycles trought fullscreen on/off
		public function switchFullScreen(e:Event = null):void {
			fireEvent(PlayerEvent.FULLSCREEN,!isFullScreen ? 1 : 0)
			if (conf.fullscreen.type != "none") setFullScreen(!isFullScreen)
		}
		
		// this gets called when stream ends
		protected function onStreamEnd():void {
			if (dragging != SEEK && controlStream.stopped) {
				
				if (conf.advertise.resource && !conf.advertise.done) {
					load(conf.start.resource,conf.start.cover,conf.start.caption)
					conf.advertise.done = true
				} else {
					// reset immediate start
					immediateStart = false
					
					switch (conf.playback.onStop) {
						case "loop":	
							fireEvent(PlayerEvent.LOOP,0)
							controlStream.restart()
							controlStream.resume()
						break;
						case "cover":
							// reshow cover
							showCoverOnTop()
						default:
							fireEvent(PlayerEvent.STOP,controlStream.duration)
					}
					showPlayOnTop()
				}				
							
			}
		}
		
		// this is used to fire events
        protected function fireEvent(type:String,value:Number = -1):void {
        	if ((value >= 0 || controlStream) && conf.events.playerEvents) dispatchEvent(new StreamEvent(type,value >= 0 ? value : controlStream.time));
        }
		
		// called on resize events
		protected function resizeHandler(e:Event):void {
			if (isFullScreen) {
				setFullScreen(false)
			} else if (conf.fullscreen.resizable) {
				resize(stage.stageWidth,stage.stageHeight)
			}
		}
		
		// stream event handler
		protected function streamEventHandler(e:StreamEvent):void {
			if (conf.events.streamEvents) dispatchEvent(e)
			var msg:* = false
			
			switch (e.type) {
				case StreamEvent.INIT:
					
					// stream starts init 
					//spinner.show()
					if (!conf.start.buffering) spinner.show()
				break;
				case StreamEvent.READY:
					// stream is ready
					if (!coverLoading) spinner.hide()
					setVisual()
				break;
				case StreamEvent.NET_ERROR:
					// connect, show spinner
					spinner.hide()
					msg = "STREAM ERROR : " + controlStream.error 
				break;
				case StreamEvent.NOT_FOUND:
					// connect, show spinner
					spinner.hide()
					msg = "CANNOT LOAD : " + controlStream.resource
				break;
				case StreamEvent.CONNECT:
					// connect, show spinner
					//spinner.show(0.1)
					if (!conf.start.buffering) spinner.show(0.1)
					msg = "CONNECTING...."
				break;
				case StreamEvent.INFO:
				break;
				case StreamEvent.BUFFERING:
					// buffering, show spinner
					if (controlStream.useSpinner) spinner.show(0.1)
					msg = "BUFFERING "
					if (controlStream.hasNumbericBuffer) msg += uint(e.value*100+.5)+"%"
				break;
				case StreamEvent.PLAY: // check this
				case StreamEvent.STREAMING:
				case StreamEvent.RESUME:
					// playback resume, hide spinner
					spinner.hide()
				case StreamEvent.CLOSE:
					// stream is closed, clear status message
					msg = ""
				break;
				case StreamEvent.STOP:
					// check for loop
					onStreamEnd()
				break;
				
			}
			
			if (msg !== false) showMessage(msg)
			
			showPlayOnTop()
			showCoverOnTop()
			
			if (e.type == StreamEvent.PLAY) {
				if (conf.advertise.playing) {
					conf.advertise.started = getTimer()
				}
			
				if (conf.description.visible) {
					hideDescription()
				} else {
					showDescription(true,conf.description.hideAfter)
				}
			}
			
			
		}
		
		// interactive events manager
		protected function evHandler(e:*):void {
			var id:String = e.target.name
						
			// if interactive event, show cursor 
			if (isFullScreen && conf.fullscreen.hideCursor > 0 && e is MouseEvent) {
				Mouse.show()
				moveCounter = 0
				mouseOver = true
			}
			
			switch (e.type) {
				case MouseEvent.MOUSE_DOWN:
					// clicks
					switch (id) {
						case "seek":
							if (controlStream) {
								// seek to position
								dragging = SEEK
								resumeOnSeekEnd = !controlStream.paused
								pause()
								seek(e.localX/100)
								showPlayOnTop()
							}
						break;
						default:
						case "visualizer":
						case "play":
							// play/pause the video
							if (controlStream && controlStream.stopped) {
								controlStream.restart()
								controlStream.resume()
								fireEvent(PlayerEvent.PLAY,0)
							} else {
								toggle()
							}
							break
						case "pause":
							// toggle pause/play
							toggle()
						break;
						case "zoom":
							switchZoom()
						break
						case "fullscreen":
							// DAMN FULLSCREEN FIREFOX BUG ... MOVED ON MOUSE_UP
	
							//switchFullScreen()
						break;
						case "volume":
							// set mute / unmute
							muted = !muted
							if (muted) {
								volume(0,false)
							} else {
								volume(conf.start.volume > 0.1 ? conf.start.volume : 0.8)
							}
						break;
						case "volumeBar":
							// set volume
							dragging = VOLUME
							volume(e.localX/volumeBar.width)
						break;
					}
				break;
				case MouseEvent.ROLL_OUT:
					mouseOver = false
				case MouseEvent.MOUSE_UP:
					switch(id) {
						case "fullscreen":
							switchFullScreen()
						break;
						default:
							switch (dragging) {
								case SEEK:
									// seek ended
									dragging = NONE
									if (controlStream.seekNeedsEnd) seek((e.localX-seekBar.x)/seekBar.width)
									if (resumeOnSeekEnd) resume()
									onStreamEnd()
								break;
								case VOLUME:
									// volume adjust ended
									dragging = NONE
								break;
							}
					}
					
				break;
				case MouseEvent.MOUSE_OVER:
					mouseOver = true
				case MouseEvent.MOUSE_OUT:
					if (id == "description" || e.target.parent.name == "description") {
						// show/hide description
						showDescription(conf.description.mouseOver = (e.type == MouseEvent.MOUSE_OVER))
					} else if (e.target is bitfade.ui.core.IMouseOver) {
						// if mouse is over/out an object which implements IMouseOver, 
						// call over method to highlight				
						e.target.over(e.type == MouseEvent.MOUSE_OVER)
					}
					
				break;
				case MouseEvent.MOUSE_MOVE:
					if (id == "drag") {
						switch (dragging) {
							case SEEK:
								// seek
								seek((e.localX-seekBar.x)/seekBar.width)
							break
							case VOLUME:
								// volume
								volume((e.localX-volumeBar.x)/volumeBar.width)
							break;
						}
					} 
				break;
				case MouseEvent.MOUSE_WHEEL:
					// use wheel for seek / volume
					var delta:Number = e.delta > 0 ? -1 : 1
					switch (id) {
						case "description":
							
						break;
						case "volume":
						case "volumeBar":
							volume(conf.start.volume+delta/10)
						break;
						default:
							if (controlStream) seek(controlStream.position+delta/20)
					}	
					
				break;
				case Event.ENTER_FRAME:
					// hide cursor when needed
					if (isFullScreen && conf.fullscreen.hideCursor > 0) {
						if (moveCounter < conf.fullscreen.hideCursor) {
							moveCounter++	
						} else {
							Mouse.hide()
							mouseOver = false
						}
					}
					
				break;
			}
			
			if (conf.controls.show == "over" || conf.controls.show == "overMin") {
				controlsTw.proxy.alpha = mouseOver ? 1 : 0
			} 
			
		}
		
		// destruct player
		public function destroy():void {
			Gc.destroy(controlStream)
			controlStream = undefined
			Gc.destroy(this)
			vid = undefined
			
		}
	}
}
/* commentsOK */