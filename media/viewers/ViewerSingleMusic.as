/*

	Base class for intros, has common methods

*/
package bitfade.media.viewers {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	import flash.xml.*
	import flash.events.*
	import flash.utils.*
			
	
	import bitfade.core.components.Xml
	import bitfade.intros.backgrounds.*
	import bitfade.ui.text.*
	import bitfade.media.streams.*
	import bitfade.utils.*
	import bitfade.effects.cinematics.*
	import bitfade.effects.*
	import bitfade.filters.*
	import bitfade.easing.*
	import bitfade.media.preview.playlist.*
	import bitfade.ui.spinners.loaders.*
	import bitfade.ui.*
	import bitfade.ui.icons.*
	import bitfade.ui.core.*
	
	public class Viewer extends bitfade.core.components.Xml {
	
		// default item values
		protected var itemDefaults:Object = {
			duration: 3	
		}
	
		// default element values
		protected var elementDefaults:Object = {
			image: {
				scale: "fit",
				align: "bottom,left",
				offset: "2,20",
				effect: "",
				shake: false,
				width: 0.6,
				height: 1,
				delay:0,
				duration:1,
				flyBy:"left"
			},
			title: {
				align: "top,left",
				offset: "0.05,0.49",
				effect: "clean,glow",
				shake: false,
				width: 0.5,
				height: 1,
				delay:.5,
				duration:1,
				flyBy:"right"
			},
			description: {
				align: "top,left",
				offset: "0.3,0.49",
				effect: "clean",
				shake: false,
				width: 0.5,
				height: 1,
				delay:.8,
				duration:1,
				flyBy:"bottom"
				
			}
			
		}
		
		// default playlist values
		protected var playlistDefaults:Object = {
		}

		// status codes
		public static const STOPPED:uint = 0
		public static const RUNNING:uint = 1
		public static const LOADING:uint = 2
	
		protected var status:uint = STOPPED
	
		// items
		protected var items: Array
	
		// component layers
		protected var topLayer:Sprite
		protected var contentLayer:Sprite
		protected var controlLayer:Sprite
		protected var backgroundLayer:Sprite
		
		protected var loading:bitfade.ui.spinners.loaders.Layer
	
		// background
		protected var back: bitfade.intros.backgrounds.Background
		
		// slideshow background
		protected var slideshow: bitfade.intros.backgrounds.Slideshow
		
		// video background
		protected var video: bitfade.intros.backgrounds.Video
		
		// textField to render text
		protected var textRenderer:bitfade.ui.text.TextField
	
		// target
		protected var target:DisplayObject
		
		// soundtrack
		public var music:bitfade.media.streams.Audio
		
		// asset loader
		protected var aL:AssetLoader
		
		// current item
		protected var currentItem:Object
		protected var currentItemIdx:uint = 0
		protected var gotData:Boolean = true;
		protected var gotVideo:Boolean = false;
		
		// playlist
		protected var playlist:bitfade.media.preview.playlist.Chooser
		protected var playlistConf:XML
		
		// controls
		protected var controlsHolder:Sprite;
		protected var pauseControl:bitfade.ui.icons.BevelGlow;
		protected var nextControl:bitfade.ui.icons.BevelGlow;
		protected var prevControl:bitfade.ui.icons.BevelGlow;
		protected var volumeControl:bitfade.ui.icons.BevelGlow;
		protected var menuControl:bitfade.ui.icons.BevelGlowText;
		protected var timerControl:bitfade.ui.Slider
		protected var playlistArea:bitfade.ui.Empty
		
		protected var paused:Boolean = false;
		protected var muted:Boolean = false;
		protected var loadNextTimer:RunNode;
		
		protected var locked:Boolean = false;
		
		// include filter in swf
		protected function includeFilterClass():void {
			var gf:bitfade.filters.Glow
			var cf:bitfade.filters.Clean
			//var tf:bitfade.filters.Thumb
		}
	
	
		override protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			if (xmlConf) {
				if (xmlConf.hasOwnProperty("playlist")) {
					// get playlist xml conf from main conf
					playlistConf = new XML(xmlConf.playlist)
					delete playlistConf.item
					delete xmlConf.playlist
					// set some other config defaults
					conf.playlist = playlistDefaults
					
				}
				
			} 
			super.init(xmlConf)
		}
	
		// pre boot functions
		override protected function preBoot():void {
		
			// set defaults
			defaults.style = {
			}
			
			defaults.controls = {
				align: "bottom,right",
				offset: "-5,-5"
			}
			
			defaults.soundtrack = {
				resource: "",
				volume: 100,
				loop:false
			}
			
			defaults.background = {
				type: "none"
			}
			
			defaults.style = {
				global: "dark",
				color: 0xA0A0A0,
				text: <style><![CDATA[
					title {
						color: #FFFFFF
						font-family: Bebas Neue;
						font-size: 60px;
						text-align: left;
					}
					description {
						color: #F0F0F0;
						font-family: Bebas Neue;
						font-size: 20px;
						text-align: left;
					}
					caption {
						color: #FFFFFF;
						font-family: PF Tempesta Seven Condensed_8pt_st;
						font-size: 8px;
						text-align: center;
					}					
				]]></style>.toString()
				
			}
			
			configName = "viewer"
			
		}
	
		// configure the intro
		override protected function configure():Boolean {
			items = conf.item
			
			conf.style.text = conf.style.text is String ? conf.style.text : conf.style.text.content
			
			aL = new AssetLoader(items,loadMusic,transformAsset)
			aL.random = true
			
			if (items && items is Array && items.length > 0) {
				addDefaults()
				Commands.run(this)
				return true
			}
			
			
			// no items defined, nothing to do
			return false
		}
		
		
		// add missing values
		protected function addDefaults():void {
			
			var item:Object
			
			var resources:Array;
			var max:uint = 0,i:uint = 0;
			var type:String;
			var element:Object;
			var count:uint = 0;
			var thumb:String;
			var caption:String;
			var title:String;
			var node:XML 
			
			conf.controls.align = Geom.splitProps(conf.controls.align)
			conf.controls.offset = Geom.splitProps(conf.controls.offset,true)
			
			for each (item in items) {
				
				resources = [];
				
				item = Misc.setDefaults(item,itemDefaults)
				
				item.id = count++
				
				title = ""
				
				if (item.element is Array) {
					max = item.element.length
					for (i=0;i<max;i++) {
						
						element = item.element[i]
					
						type = element.type;
						
						if (!elementDefaults[type]) element.type = type ="description"
						
						if (element.type == "title") title = element.content
						
						element = Misc.setDefaults(element,elementDefaults[type])
						
						if (element.width <= 1) element.width *= w;
						if (element.height <= 1) element.height *= h;
						
						element.align = Geom.splitProps(element.align)
						element.offset = Geom.splitProps(element.offset,true)
												
						if (Math.abs(element.offset.w) < 1) element.offset.w *= w;
						if (Math.abs(element.offset.h) < 1) element.offset.h *= h;
						
						
						if (type == "image") {
							if (item.element[i].resource) {
								resources.push("[element"+i+"]|"+item.element[i].resource)
							} else {
								//delete item.element[i]
							}
						}
					}
					
				}
				
				if (item.background) resources.push("[background]|"+item.background)
				if (item.video2) {
					resources.push("[video]|"+aL.getCustomUrl(item.video,loadVideo))
				}
				
				if (resources) item.resource = resources
				
				thumb = item.thumbnail
				
				if (thumb) {
					
					node = <item key={item.id} resource={thumb} ></item>
					
					if (item.caption) {
						caption = item.caption[0].content
					} else if (title) {
						caption = title
					}
					
					if (!playlistConf) {
						playlistConf = <playlist></playlist>
					}
					
					if (caption) {
						node.appendChild(<caption>{"<caption>"+caption+"</caption>"}</caption>)
					}
					
					playlistConf.appendChild(node)
				}
							
			}
			
		}
		

		
		protected function loadVideo(id:uint) {
			//Stream.loader(id,aL,250000)
		
			if (status == LOADING || !gotVideo) {
				gotVideo = true
				// check if video is same as current displayed
				if (video.currentPlayed(aL.getResourceFromID(id))) {
					aL.customLoaderComplete(id,true)
				} else {
					video.freeze()
					Stream.loader(id,aL,250000)
				}
			} else {
				aL.customLoaderComplete(id,false)
			}
		}
		
		// load intro background
		protected function background():void {
			loading.show()
			//backgroundLayer.addChild(new bitfade.intros.backgrounds.Intro(w,h,{color:0x804040,color2:0xFF0000}))
			//backgroundLayer.addChild(new bitfade.intros.backgrounds.Intro(w,h,{color:0xFFFFFF,color2:0x000020}))
			//backgroundLayer.addChild(new bitfade.intros.backgrounds.Image(w,h,{resource:"resources/images/Depositphotos_3011722_L.jpg"}))
			//backgroundLayer.addChild(new bitfade.intros.backgrounds.Image(w,h,{resource:"resources/images/Depositphotos_1870330_XL.jpg"}))
			// 
			
			//var a = new bitfade.intros.backgrounds.Image(w,h,{resource:"resources/images/Depositphotos_3011722_L.jpg"})
			//a.cacheAsBitmap = true
			//backgroundLayer.addChild(a)
			
			slideshow = new bitfade.intros.backgrounds.Slideshow(w,h)
			backgroundLayer.addChild(slideshow)
			slideshow.start()
			
			video = new bitfade.intros.backgrounds.Video(w,h)
			backgroundLayer.addChild(video)
			video.start()
			
			//back = new bitfade.intros.backgrounds.BeatWall(2*w/3,h,conf.background)
			back = new bitfade.intros.backgrounds.BeatTrails(w,h,conf.background)
			back.blendMode = "add"
			back.alpha= 1
			
			if (back) {
				backgroundLayer.addChild(back)
				back.onReady(loadAssets)
			} else {
				loadAssets()
			}
		}
		
		protected function resizeAsset(asset:Bitmap,tw:uint,th:uint,scale:String = "fill",xAlign:String = "center",yAlign:String = "center") {
			// auto crop
			var cropped:BitmapData = Crop.auto(asset)
					
			Gc.destroy(Bitmap(asset).bitmapData)
			
			var mat:Matrix = Geom.getScaleMatrix(Geom.getScaler(scale,xAlign,yAlign,tw,th,cropped.width,cropped.height))
				
			// scale
			var scaled:BitmapData = Snapshot.take(cropped,Bdata.create(tw,th),0,0,mat)
				
			cropped = Gc.destroy(cropped)
				
			Bitmap(asset).bitmapData = scaled
			
		}
		
		// resize images assets when they are loaded
		protected function transformAsset(asset:*,item:*) {
		
			if (asset.background is Bitmap) {
				resizeAsset(asset.background,w,h)
			} 
			
			if (asset.element) {
				var elConf:Object
			
				for (var idx:String in asset.element) {
					elConf = item.element[parseInt(idx)]
					resizeAsset(asset.element[idx],elConf.width,elConf.height,elConf.scale,elConf.align.w,elConf.align.h)
				}
			
			}
			
			return asset
		}
		
		// start loading external assets
		protected function loadAssets():void {
			//loadMusic()
			currentItemIdx = 0
			currentItem = items[currentItemIdx]
			
			loading.link(aL)
			aL.start()
			
			
			/* REMOVE THIS */
			/*
			Run.after(1,function () {
				Run.every(0.05,function() {
					if (!loading.visible) {
						currentItemIdx += -1
						checkItemIdx()
					}
				},235)
			})
			*/
			
		}
		
		// load soundtrack
		protected function loadMusic():void {
			if (conf.soundtrack.resource) {
				music = new bitfade.media.streams.Audio()
				// add event listeners
				bitfade.utils.Events.add(music,StreamEvent.GROUP_PLAYBACK,musicEventHandler,this)
				music.load(conf.soundtrack.resource,false)
				muted = true
				mute()
			} else {
				controller()
			}
		}
		
		// handle soundtrack events
		protected function musicEventHandler(e:StreamEvent):void {
			switch (e.type) {
				case StreamEvent.PLAY:
					controller()
				break;
				case StreamEvent.RESUME:
				break;
				case StreamEvent.STOP:
					if (conf.soundtrack.loop) {
						// restart music playback
 						music.seek(0)
 						music.resume()
					} 					
				break
			}
			
		}
		
		// begin 
		protected function activate():void {
			loading.hide()
			if (back) {
				back.start()
			}
			contentLayer.visible = backgroundLayer.visible = true
			aL.readyCallBack = assetLoaded
			assetReady()
			start()
			
			
			//playlist.show()
		}
		
		// hanle intro status changes
		protected function controller() {
		
			var ready:Boolean = gotData
			switch (status) {
				case STOPPED:
					if (ready) {
						status = RUNNING
						activate()
					}
				break;
				case RUNNING:
					if (!ready) {
						status = LOADING
						//pause()
					} 
				break;
				case LOADING:
					if (ready) {
						status = RUNNING
						//resume()
					}
				break;
			}
			
			if (status == LOADING) {
				loading.show(0.1)
			} else {
				loading.hide()
			}
		
		}
		
		protected function assetLoaded() {
			if (!gotData) {
				assetReady()
			}
		}
			
		
		protected function start():void {
		}
		
		// asset is loaded, process it
		protected function assetReady() {
		
			/*
			if (currentItem.video) {
				video.load(currentItem.video)
				trace(currentItem.video)
				status = LOADING
				gotData = false
				controller()
				if (!video.playbackReady) return
				trace("HERE")
			}
			
			return
			*/
			
			gotData = true
			controller()
			//Run.after(1,loading.show)

			displayItem()
			
		}
		
		protected function cleanContent() {
		
			var shot:Bitmap = new Bitmap(Snapshot.take(contentLayer,null,w,h)) 
			Gc.destroyChildrens(contentLayer);
			var eff:Effect = bitfade.effects.TweenDestroy.create(shot)
			//var eff:Effect = bitfade.effects.cinematics.Transition.create(shot)
			contentLayer.addChild(eff)
			eff.ease = bitfade.easing.Cubic.Out
			eff.actions("fadeOut",.5)
			//eff.actions("transition",1)
			eff.start(w,h)
	
		}
		
		protected function displayItem() {
		
			var elements:Array = currentItem.element
			
			var externalData:Object = aL.getData(currentItem)
		
			cleanContent()
			
			loadNextTimer = Run.after(currentItem.duration,nextItem)
			if (paused || (playlist && playlist.visible) ) Run.pause(loadNextTimer)
			
			
			if (slideshow) slideshow.show(externalData.background)
			if (currentItem.video && externalData.video is Stream) {
				video.load(externalData.video)
				externalData.video = undefined
			}
			//if (currentItem.video) video.load(currentItem.video)
			
			if (!elements) return
			
			
			var i:uint = 0;
			var max:uint = elements.length
			var element:Object
		
			var eff:Effect
			var scaler:Object
		
			for (;i<max;i++) {
				element = elements[i]
				target = undefined
				
				if (element.type == "image") {
					target = externalData.element[i]
				} else {
					textRenderer.maxWidth = element.width
					textRenderer.maxHeight = element.height
					textRenderer.content("<"+element.type+">" + element.content + "</"+element.type+">")
					target = new Bitmap(Crop.auto(textRenderer))
				}
				
				if (!target) {
					trace(currentItemIdx,currentItem.element[i].resource)					
				} 
				
				target = bitfade.filters.Filter.apply(target,element.effect)
		
				target.alpha = 0
				
				eff = bitfade.effects.cinematics.OutlineHit.create(target)
				
				if (element.shake) {
					eff.onComplete(shake)
				
				}
				
				eff.actions("wait",element.delay)
				eff.actions("oulineFadeIn",element.duration)
				
				eff.start(w,h,{flyBy: element.flyBy})
			
				scaler = Geom.getScaler("none",element.align.w,element.align.h,w,h,eff.realWidth,eff.realHeight)
				
				eff.x = int(scaler.offset.w + element.offset.w - Cinematic(eff).offset.x)
				eff.y = int(scaler.offset.h + element.offset.h - Cinematic(eff).offset.y)
			
				// add the effect
				contentLayer.addChild(eff)
				
			}
			
			
			
		}
		
		// playing effect has ended
		protected function shake(current:Effect = null):void {
			
			var eff:Effect = bitfade.effects.Shake.create(current.target)
			
			eff.actions("followMusic",uint.MAX_VALUE)
			eff.start()
			contentLayer.addChild(eff)
						
			
		}
		
		// load next item
		protected function nextItem() {
			currentItemIdx++
			checkItemIdx()
		}
		
		protected function checkItemIdx() {
			
			// clear existing timer
			loadNextTimer = Run.reset(loadNextTimer)
			
			timerControl.pos(0)
			
			currentItemIdx = Math.min(Math.max(0,currentItemIdx),items.length);
			
			var loop:Boolean = true
			
			if (currentItemIdx == items.length && loop) { 
				// loop intro
				currentItemIdx = 0
			}
			
			getItem()
		}
		
		protected function getItem() {
			if (currentItemIdx == items.length) {
				// last item
				//end()
				return
			}
			
			// load next item
			currentItem = items[currentItemIdx]
			
			loading.show(0.1)
			
			gotData = false
			
			if (aL.ready(currentItem)) {
				assetReady()
			} else {
				controller()
			}
		}
		
		
		// build layers
		override protected function build():void {
		
			scrollRect = new Rectangle(0,0,w,h)
		
			textRenderer = new bitfade.ui.text.TextField({
				styleSheet:	conf.style.text,
				maxWidth: w*3/6,
				maxHeight: h,
				filters : [ new flash.filters.DropShadowFilter(1,45,0,.5,1,2)  ],
				thickness:	0,
				sharpness:  0
			})
			
			backgroundLayer = new Sprite()
			contentLayer = new Sprite()
			controlLayer = new Sprite();
			topLayer = new Sprite()
			
			topLayer.mouseEnabled = false
			
			
			contentLayer.visible = backgroundLayer.visible = false
			
			addChild(backgroundLayer)
			addChild(contentLayer)
			addChild(controlLayer)
			addChild(topLayer)
			
			if (playlistConf) {
				playlistConf.caption = new XMLNode(1,"")
			
				// set playlist caption style = player caption style
				playlistConf.style.text = new XMLNode(3,conf.style.text)
				
				// no external font loading for playlist coz we do this in player
				playlistConf.external.@font = ""
				
				// start as hidden
				playlistConf.@visible = false
				
				// create the playlist
				playlist = new bitfade.media.preview.playlist.Chooser(w,82,playlistConf)
				playlist.y = h-82
				playlist.clickHandler(playlistClick,true)
				
				
				bitfade.utils.Events.add(playlist,[
					MouseEvent.ROLL_OUT
				],evHandler,this)
				
				playlistArea = new Empty(w,20,true)
				playlistArea.name = "playlistArea"
				playlistArea.y = h - 20
			
						
				controlLayer.addChild(playlistArea)
				controlLayer.addChild(playlist)	
				playlist.name = "playlist"
				
			}
			
			buildControls()
			
			bitfade.utils.Events.add(this,[
					MouseEvent.MOUSE_DOWN,
					MouseEvent.MOUSE_OVER,
					MouseEvent.MOUSE_OUT
			],evHandler)
				
				
			
			//contentLayer.addChild(textRenderer)
			loading = new bitfade.ui.spinners.loaders.Layer(w,h,conf.style.color)
			
			topLayer.addChild(loading)
		}
		
		protected function buildControls() {
		
			var offset:uint = 0
			var spacing:uint = 18
		
			bitfade.ui.icons.BevelGlow.setStyle(conf.style.global,[-1,conf.style.color])
		
			controlsHolder = new Sprite();
			controlsHolder.blendMode = "layer"
			controlsHolder.name = "controlsHolder"
			controlsHolder.alpha = 0.3
			
			//controlLayer.addChild(controlsHolder)
			controlLayer.addChildAt(controlsHolder,0)
				
				
			menuControl = new bitfade.ui.icons.BevelGlowText("menu","MENU",16,42,false)
			offset += menuControl.width + 4
			controlsHolder.addChild(menuControl)
				
			volumeControl = new bitfade.ui.icons.BevelGlow("volume","volume")
			volumeControl.x = offset
			offset += spacing
			controlsHolder.addChild(volumeControl)
				
			pauseControl = new bitfade.ui.icons.BevelGlow("pause","pause")
			pauseControl.x = offset
			offset += spacing-4
			controlsHolder.addChild(pauseControl)
			
			prevControl = new bitfade.ui.icons.BevelGlow("prev","prev")
			prevControl.x = offset
			offset += spacing
			controlsHolder.addChild(prevControl)
			
			nextControl = new bitfade.ui.icons.BevelGlow("next","next")
			nextControl.x = offset
			offset += spacing
			controlsHolder.addChild(nextControl)
			
			Slider.setStyle(conf.style.global,[-1,-1,-1,conf.style.color,-1,-1,-1,-1,-1])
			
			timerControl = new Slider(controlsHolder.width,1,1)
			timerControl.y = (controlsHolder.height + 2)
			timerControl.mouseEnabled = false
			timerControl.mouseChildren = false
			
			timerControl.alpha = 0.8
			
			var scaler:Object = Geom.getScaler("none",conf.controls.align.w,conf.controls.align.h,w,h,controlsHolder.width,controlsHolder.height)
				
			controlsHolder.x = int(scaler.offset.w + conf.controls.offset.w )
			controlsHolder.y = int(scaler.offset.h + conf.controls.offset.h )
			
			var e:Empty = new Empty(controlsHolder.width+30,controlsHolder.height+30,true)
			e.mouseEnabled = false
			e.x = -conf.controls.offset.w - 30
			e.y = -conf.controls.offset.h - 30 
			controlsHolder.addChildAt(e,0)
			
			controlsHolder.addChild(timerControl)
			
			var gfx:Graphics = controlsHolder.graphics
			gfx.beginFill(0,.3) 
			gfx.drawRoundRect(-4,-4,controlsHolder.width,controlsHolder.height,8,8)
			gfx.endFill()
			
			bitfade.utils.Events.add(controlsHolder,[
					MouseEvent.ROLL_OVER,
					MouseEvent.ROLL_OUT
			],evHandler,this)
			
			Run.every(Run.FRAME,showTimer)
			
			playlistArea.width = w - controlsHolder.width

		}
		
		protected function showTimer() {
			if (loadNextTimer && !paused && !(playlist && playlist.visible)) {
				var now:Number = getTimer()
				var pos:Number = Math.max(0,Math.min(1,1-(loadNextTimer.runAt-now)/(currentItem.duration*1000)))
				timerControl.pos(pos)
			}
		}
		
		protected function playlistShow(show:Boolean = true) {
			if (show) {
				playlist.show()
				FastTw.tw(controlsHolder).alpha = 0
				Run.pause(loadNextTimer)
			} else {
				playlist.hide()
				FastTw.tw(controlsHolder).alpha = 0.3
				if (!paused) {
					Run.resume(loadNextTimer)
				}
			}
		}
		
		public function pause() {
			paused = !paused
			if (loadNextTimer) {
				if (paused) {
					Run.pause(loadNextTimer)
				} else {
					Run.resume(loadNextTimer)
				}
			
			}
			pauseControl.over(paused)
		}
		
		public function mute() {
			muted = !muted
			music.volume(muted ? 0 : conf.soundtrack.volume/100)
			volumeControl.over(!muted)
		}


		
		protected function evHandler(e:MouseEvent) {
			var id:String = e.target.name
			var mouseOver:Boolean
			//trace(id,e.type)
			
			switch (e.type) {
				case MouseEvent.MOUSE_OVER:
				case MouseEvent.MOUSE_OUT:
					mouseOver = (e.type == MouseEvent.MOUSE_OVER)
					
					if (e.target is bitfade.ui.core.IMouseOver) {
						switch (e.target) {
							case pauseControl:
								if (!paused) e.target.over(mouseOver)
							break;
							case volumeControl:
								if (muted) e.target.over(mouseOver)
							break;
							default:
								e.target.over(mouseOver)	
						}
					}
					
					switch (id) {
						case "playlistArea":
							if (mouseOver) playlistShow()
						break;
					}
					
				break;
				case MouseEvent.MOUSE_DOWN:
					switch (id) {
						case "menu":
							playlistShow()
						break;
						case "next":
						case "prev":
							currentItemIdx += (id == "next" ? +1 : -1)
							checkItemIdx()
						break;
						case "pause":
							pause()
						break;
						case "volume":
							mute()
						break;
					}
					
				break;
				case MouseEvent.ROLL_OVER:
				case MouseEvent.ROLL_OUT:
					mouseOver = (e.type == MouseEvent.ROLL_OVER)
					switch (id) {
						case "playlist":
							if (!mouseOver && !loading.visible) {
								playlistShow(false)
							}
						break;
						case "controlsHolder":
							if (playlist && playlist.visible) break
							FastTw.tw(controlsHolder).alpha = mouseOver ? 1 : 0.3
						break;
					}
				break;
				
			}
		}
		
		protected function playlistClick(item:Object) {
			goto(parseInt(item.key))
		}
		
		public function goto(id:uint) {
			currentItemIdx = id
			checkItemIdx()
		}
		
		// init intro display
		override protected function display():void {
			super.display()
			background();
		}
		
		// destroy intro
		override public function destroy():void {
			aL.destroy()
			aL = undefined
			if (music) {
				music.destroy()
				music = undefined
			}
			if (loadNextTimer) Run.reset(loadNextTimer)
			
			
			super.destroy()
		}
		
	
	}
}
/* commentsOK */