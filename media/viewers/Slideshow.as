/*

	Base class for slideshows

*/
package bitfade.media.viewers {
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	import flash.xml.*
	import flash.events.*
	import flash.utils.*		
	
	import bitfade.media.players.*
	import bitfade.media.streams.*
	import bitfade.media.visuals.*
	import bitfade.core.components.Xml
	import bitfade.intros.backgrounds.*
	import bitfade.ui.text.*
	import bitfade.media.streams.*
	import bitfade.utils.*
	import bitfade.effects.cinematics.*
	import bitfade.effects.*
	import bitfade.filters.*
	import bitfade.media.preview.playlist.*
	import bitfade.ui.spinners.loaders.*
	import bitfade.ui.*
	import bitfade.ui.icons.*
	import bitfade.ui.core.*
	import bitfade.easing.*
	
	public class Slideshow extends bitfade.core.components.Xml {
	
		// default item values
		protected var itemDefaults:Object = {
		
			duration: 3,	
			
			soundtrack:  {
				resource: "",
				preload: 250,
				volume: 100,
				loop:true
			},
			
			sfx: {
				volume: 100
			}
			
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
				flyBy:"left",
				link:"",
				target:""
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
				flyBy:"right",
				link:"",
				target:""
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
				flyBy:"bottom",
				link:"",
				target:""
				
			}
			
		}
		
		// default group values
		protected var groupDefaults:Object = {
			layout: "none",
			type: "image",
			shake: false,
			delay: 1,
			delayincrement: 0.1, 
			duration: 1,
			spacing: 10, 
			width: 1,
			height: 1, 
			align: "bottom,center",
			galign: "center,center",
			flyBy: "none"
		}
		
		// default backgrounds values
		protected var backgroundDefaults:Object = {
			
			solid: {
				color: 0
			},
			
			gradient: {
				color: -1,
				color2: -1,
				style:"dark"
			},

			video:  {
				offset: "0,0",
				align: "top,left",
				resource: "",
				preload: 250,
				volume: 0
			},
			
			slideshow:  {
				offset: "0,0",
				align: "top,left",
				resource: "",
				transition: "hilight",
				duration: 1,
				delay:0
			},
			
			beatwall: {
				offset: "0,0",
				align: "top,left",
				blendMode: "add"
			},
			
			beattrails: {
				offset: "0,0",
				align: "top,left",
				blendMode: "add"
			},
			
			reflection: {
				size: 50,
				align: "bottom,left"
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
		protected var overlayLayer:Sprite
		protected var backgroundLayer:Sprite
		
		protected var loading:bitfade.ui.spinners.loaders.Layer
			
		// textField to render text
		protected var textRenderer:bitfade.ui.text.TextField
	
		// target
		protected var target:DisplayObject
		
		// soundtrack
		public var music:bitfade.media.streams.Audio
		protected var musicVolume:Number = 0;
		
		// asset loader
		protected var aL:AssetLoader
		
		// current item
		protected var currentItem:Object
		protected var currentItemIdx:uint = 0
		
		// semaphores
		protected var gotData:Boolean = true;
		protected var gotVideo:Boolean = false;
		protected var gotAudio:Boolean = false;
		
		// current played soundtrack
		protected var currentSoundTrack:String = ""
		
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
		
		// needed booleans for ui controls
		protected var paused:Boolean = false;
		protected var wasPaused:Boolean = false;
		protected var muted:Boolean = false;
		protected var loadNextTimer:RunNode;
		
		protected var locked:Boolean = false;
		
		// backgrounds
		protected var backgroundsMap:Dictionary;
		protected var backgroundsID:Dictionary;
		protected var backgrounds:Dictionary;
		protected var labels:Dictionary;
		
		// mini player
		protected var player:bitfade.media.players.MiniPlayer
		
		// sound effects
		protected var sfx:Object
		
		// include filters in swf
		protected function includeFilterClass():void {
			var gf:bitfade.filters.Glow
			var cf:bitfade.filters.Clean
			var bf:bitfade.filters.Box
		}
		
		// include streams in swf
		protected function includeStreamClass():void {
			bitfade.media.streams.Audio.addClass()
			bitfade.media.streams.Video.addClass()
			bitfade.media.streams.Youtube.addClass()
			
			var videoV:bitfade.media.visuals.Video
			var youtubeV:bitfade.media.visuals.Youtube
		}
		
		// include backgrounds in swf
		protected function includeBackgroundClass():void {
			backgroundsMap = new Dictionary()
			backgroundsMap["beattrails"] = bitfade.intros.backgrounds.BeatTrails
			backgroundsMap["beatwall"] = bitfade.intros.backgrounds.BeatWall
			backgroundsMap["slideshow"] = bitfade.intros.backgrounds.SlideShow
			backgroundsMap["video"] = bitfade.intros.backgrounds.Video
			backgroundsMap["gradient"] = bitfade.intros.backgrounds.Intro
			backgroundsMap["solid"] = bitfade.intros.backgrounds.Solid
			backgroundsMap["reflection"] = bitfade.intros.backgrounds.Reflection
		}
	
	
		override protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			includeStreamClass()
			includeBackgroundClass()
			if (xmlConf) {
				if (xmlConf.hasOwnProperty("playlist")) {
					// get playlist xml conf from main conf
					playlistConf = new XML(xmlConf.playlist)
					delete playlistConf.item
					delete xmlConf.playlist
					// set some other config defaults
					conf.playlist = playlistDefaults
					
				}
				
				if (xmlConf.style && xmlConf.style.@global == "light") {
					defaults.style.color = 0x202020
				}
				
			} 
			
			super.init(xmlConf)
		}
		
		// preload external resources
		override protected function preLoadExternalResources():void {
			
			parseBackgroundConfig()				
		
			// add a loading visual element
			loading = new bitfade.ui.spinners.loaders.Layer(w,h,conf.style.color)
			addChild(loading)
			// bind it to asset loader
			loading.link(ResLoader.instance)
			loading.show()
		}
		
		override protected function resourcesLoaded(content:* = null):void {
			// extract sound effects, if any
			if (content && content.hasOwnProperty("soundFxLibrary") && content.soundFxLibrary) sfx = Sfx.extract(content.soundFxLibrary)
			// save external loaded resources for later use
			conf.external = content
			
			super.resourcesLoaded(content)
		}
	
		// pre boot functions
		override protected function preBoot():void {
		
			// set defaults
			defaults.style = {
			}
			
			defaults.backgrounds = {
			}
			
			defaults.controls = {
				enabled: true,
				align: "bottom,right",
				offset: "-5,-5"
			}
			
			defaults.background = {
				type: "none"
			}
			
			// default style
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
			
			defaults.loader = {
				preloadAudio: false,
				preloadVideo: false
			}
			
			configName = "slideshow"
			
		}
	
		// configure the slideshow
		override protected function configure():Boolean {
			items = conf.item
			
			conf.style.text = conf.style.text is String ? conf.style.text : conf.style.text.content
			
			// create the asset loader
			aL = new AssetLoader(items,controller,transformAsset)
			aL.random = true
			
			if (items && items is Array && items.length > 0) {
				addDefaults()
				Commands.run(this)
				return true
			}
			
			
			// no items defined, nothing to do
			return false
		}
		
		// compute alignment and position of items/backgrounds
		protected function fixAlignAndSize(element:Object):void {
			if (!element.width) element.width = 1
			if (!element.height) element.height = 1
		
			if (element.width <= 1) element.width *= w;
			if (element.height <= 1) element.height *= h;
						
			if (!element.align) element.align = "top.left"
			if (!element.offset) element.offset = "0,0"
						
			element.align = Geom.splitProps(element.align)
			element.offset = Geom.splitProps(element.offset,true)
												
			if (element.galign) element.galign = Geom.splitProps(element.galign)
												
			if (Math.abs(element.offset.w) < 1) element.offset.w *= w;
			if (Math.abs(element.offset.h) < 1) element.offset.h *= h;
			
		}
		
		// parse backgrounds configuration
		protected function parseBackgroundConfig() {
		
			backgrounds = new Dictionary()
			backgroundsID = new Dictionary()
			
			var element:Object;
			var type:String;
			var bID:uint = 0
			
			if (conf.backgrounds) {
				for each (element in conf.backgrounds.background) {
					type = element.type;
					if (backgroundsMap[type]) {
						
						if (!element.style) element.style = conf.style.global
						
						if (!element.id) {
							element.id = bID
						}
						
						// set background defaults
						if (backgroundDefaults[type]) {
							element = Misc.setDefaults(element,backgroundDefaults[type])
						}
												
						backgrounds[bID] = element
						backgroundsID[element.id] = bID
						
						// preload the resource, if defined
						if (element.resource) {
							conf.external["background"+bID] = "[background"+bID+"]|"+element.resource
						}

						
						bID++
					}
				}
			} 
			
		}
		
		// add missing values
		protected function addDefaults():void {
			
			var item:Object
			
			var resources:Array;
			var max:uint = 0,i:uint = 0;
			var type:String;
			var element:Object;
			var group:Object;
			var gDef:Object;
			var scaler:Object;
			var count:uint = 0;
			var thumb:String;
			var caption:String;
			var title:String;
			var node:XML 
			
			var bID:uint = 0
			var id:uint = 0;
			
			var key:String = "";
			
			// change defaults for light style
			if (conf.style.global == "light") {
				elementDefaults.title.effect = "clean"
				elementDefaults.description.effect = ""
			}
			
			// get position,alignment of controls
			conf.controls.align = Geom.splitProps(conf.controls.align)
			conf.controls.offset = Geom.splitProps(conf.controls.offset,true)
			
			
			for each (item in items) {
				
				resources = [];
				
				// set item defaults
				item = Misc.setDefaults(item,itemDefaults)
				
				item.id = count++
				
				// extract the label, if defined
				if (item.label) {
					if (!labels) labels = new Dictionary()
					labels[item.label] = item.id
				}
				
				title = ""
				
				// if we have a group
				if (item.group is Array) {
					var gw:uint
					var gh:uint
					var gi:uint
					var gn:uint
					var gd:uint
					var gs:uint
					var gx:uint
					var gy:uint
					
					var prop:Object;
				
					max = item.group.length
					
					// get all item from group
					for (i=0;i<max;i++) {
						group = item.group[i]
						if (group && group.element) {
						
							// set group defaults
							group = Misc.setDefaults(group,groupDefaults)
							gDef = Misc.setDefaults(group,groupDefaults,true)
							
							if (group.layout != "none") {
							
								type = group.layout == "vertical" ? "vertical" : "horizontal"
								
								fixAlignAndSize(group)
								
								gn = group.element.length
								gi = 0
								gw = group.width
								gh = group.height
								
								gs = parseInt(group.spacing)
									
								gd = (((type == "horizontal" ? gw : gh)-(gn-1)*gs)/gn)
								
								gs += gd
											
								scaler = Geom.getScaler("none",group.galign.w,group.galign.h,w,h,group.width,group.height)
					
								gx = int(scaler.offset.w+group.offset.w)
								gy = int(scaler.offset.h+group.offset.h)
								
							
							} 
							
							// set align/position for each group element 
							for each (element in group.element) {
								
								for (prop in groupDefaults) {
									if (element[prop] == undefined) element[prop] = gDef[prop]
								}
									
								if (group.layout != "none") {
								
									
									if (type == "horizontal") {
										element.width = gd
										element.height = gh
										element.offset = gy+","+(gx+gi*gs)
									} else {
										element.width = gw
										element.height = gd
										element.offset = (gy+gi*gs)+","+gx
									}
									
									element.group = "yes"
								
								}
								
								if (group.delayincrement) {
									element.delay = parseFloat(element.delay)+gi*group.delayincrement
								}
								
								
								if (!item.element) item.element = []
								item.element.push(element)
								gi++
							}
						}
						delete item.group[i]
					}
				}
				
				
				// set element values
				if (item.element is Array) {
					max = item.element.length
					for (i=0;i<max;i++) {
						
						element = item.element[i]
					
						type = element.type;
						
						if (!elementDefaults[type]) type ="description"
						
						if (element.type == "title") title = element.content
						
						// set element defaults
						element = Misc.setDefaults(element,elementDefaults[type])
						
						fixAlignAndSize(element)
						
						// assign global style if not defined
						if (!element.style) element.style = conf.style.global
								
						// set destination label
						if (element.goto) {
							element.link = element.goto
							element.target = "label"
							delete element.goto
						}
						
						// push the resource into asset loader list
						if (type == "image") {
							if (item.element[i].resource) {
								resources.push("[element"+i+"]|"+item.element[i].resource)
							} else {
								//delete item.element[i]
							}
						}
					}
					
				}
				
				bID = 0
				// handle item background
				for each (element in item.background) {
					
					id = element.id != null ? backgroundsID[element.id] : bID++
					element.id = id
					
					if (!element.resource || !backgrounds[id]) continue
					key="[background"+id+"]|"
										
					type = backgrounds[id].type
					type = backgroundsMap[type].resourceType
					
					if (type == "video") {
						element.preload = fixPreloadBytes(element.preload)
						resources.push(key+aL.getCustomUrl(element.resource,loadVideo,element))
 					} else if (type == "display") {
 						resources.push(key+element.resource)
 					}
 				}
				
				// handle item soundtrack
				if (item.soundtrack.resource) {
					item.soundtrack.preload = fixPreloadBytes(item.soundtrack.preload)
					resources.push("[soundtrack]|"+aL.getCustomUrl("audio:default:"+item.soundtrack.resource,loadMusic))
				}
				
				
				if (resources) item.resource = resources
				
				thumb = item.thumbnail
				
				// add item thumbnail to playlist
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
		
		// compute bytes to preload for video/mp3
		protected function fixPreloadBytes(bytes:*) {
			bytes = bytes ? parseInt(bytes) : 250
			bytes = Math.max(bytes,64)
			return bytes*1024;
		}

		
		// load a video
		protected function loadVideo(id:uint) {
			if (conf.loader.preloadVideo || status == LOADING || !gotVideo) {
				gotVideo = true
				// check if video is same as current displayed
						
				var conf:Object = aL.getConfFromID(id)
				
				var video: bitfade.intros.backgrounds.Video = backgrounds[conf.id]								
				
				if (video.currentPlayed(aL.getResourceFromID(id))) {
					aL.customLoaderComplete(id,true)
				} else {
					video.freeze()
					Stream.loader(id,aL,conf.preload)
				}
			} else {
				aL.customLoaderComplete(id,false)
			}
		}
		
		// load mp3
		protected function loadMusic(id:uint) {
			var requestedTrack:String = aL.getResourceFromID(id)
			
			if (conf.loader.preloadAudio || !gotData || status == LOADING || !gotAudio) {
				gotAudio = true
				// check if audio is same as current played
				if (requestedTrack == currentSoundTrack) {
					aL.customLoaderComplete(id,true)
				} else {
					currentItem.soundtrack.name = requestedTrack
					Stream.loader(id,aL,currentItem.soundtrack.preload)
				}
			} else {
				aL.customLoaderComplete(id,false)
			}
		}
		
		// create backgrounds
		protected function background():void {
			
			var bg: bitfade.intros.backgrounds.Background
			var bgConf: Object
			var scaler:Object
		
			var preloadedBgResources:Object = {}
		
			if (conf.external && conf.external.hasOwnProperty("background")) {
				preloadedBgResources = conf.external.background
			}
		
			for (var id:* in backgrounds) {
				bgConf = backgrounds[id]
				
				fixAlignAndSize(bgConf)
				
				backgrounds[id] = new backgroundsMap[bgConf.type](bgConf.width,bgConf.height,bgConf)
				
				scaler = Geom.getScaler("none",bgConf.align.w,bgConf.align.h,w,h,bgConf.width,bgConf.height)
				
				backgrounds[id].x = int(scaler.offset.w + bgConf.offset.w)
				backgrounds[id].y = int(scaler.offset.h + bgConf.offset.h)
				
				
				if (bgConf.blendMode) backgrounds[id].blendMode = bgConf.blendMode
				if (bgConf.alpha) backgrounds[id].alpha = bgConf.alpha
				backgroundLayer.addChild(backgrounds[id])
				backgrounds[id].start()
				
				if (preloadedBgResources[id]) {
					backgrounds[id].show(preloadedBgResources[id])
				}
			}
			
			loadAssets()
			
		
		}
		
		// resize a loaded asset
		protected function resizeAsset(asset:Bitmap,tw:uint,th:uint,scale:String = "fill",xAlign:String = "center",yAlign:String = "center") {
			// auto crop
			if (!asset) return
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
		
			/*
			if (asset.background is Bitmap) {
				resizeAsset(asset.background,w,h)
			} 
			*/
			
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
			
		}
		
		// begin 
		protected function activate():void {
			// hide loading layer
			showLoadingLayer(false)
			// display content
			contentLayer.visible = backgroundLayer.visible = true
			if (controlLayer) controlLayer.visible = true
			aL.readyCallBack = assetLoaded
			assetReady()
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
					} 
				break;
				case LOADING:
					if (ready) {
						status = RUNNING
					}
				break;
			}
			
			showLoadingLayer(status == LOADING)
			
		}
		
		protected function assetLoaded() {
			if (!gotData) {
				assetReady()
			}
		}
			
		
		// asset is loaded, process it
		protected function assetReady() {
			gotData = true
			controller()
			displayItem()
		}
		
		// clean content layer
		protected function cleanContent() {
			// creat a screenshot
			var shot:Bitmap = new Bitmap(Snapshot.take(contentLayer,null,w,h))
			// remove all element
			Gc.destroyChildrens(contentLayer);
			// fade out the screenshot
			var eff:Effect = bitfade.effects.TweenDestroy.create(shot)
			contentLayer.addChild(eff)
			eff.ease = bitfade.easing.Cubic.Out
			eff.actions("fadeOut",.5)
			eff.start(w,h)
	
		}
		
		// update backgrounds with current item settings
		protected function changeBackgrounds(externalData:Object):void {
			var id:uint
			
			for each (var element:Object in currentItem.background) {
				id = element.id
				if (!element.resource) {
					backgrounds[id].show(null,element)
				} else if (externalData["background"][id] && externalData["background"][id] !== true) {
					backgrounds[id].show(externalData["background"][id],element)
					if (!aL.fullCached)	{
						// remove the resources only if assets are not all cached
						externalData["background"][id] = undefined
					}
				}
			}
		}
		
		// update soundtrack with current item settings
		protected function changeSoundtrack(externalData:Object):void {
			if (currentItem.soundtrack && externalData && externalData.soundtrack is Stream) {
				// update current played soundtrack
				currentSoundTrack = currentItem.soundtrack.name
				// if is the same, do nothing
				if (music == externalData.soundtrack) return
				if (music) {
					if (aL.fullCached) {
						// if all resources are cached, just fadeout sound and rewind for later user
						music.fadeRewind()
					} else {
						// destroy current soundtrack
						music.fadeDestroy()
					}
				} 
				
				// assign and play the new soundtrack
				music = externalData.soundtrack
				music.loop = currentItem.soundtrack.loop 
				musicVolume = currentItem.soundtrack.volume/100
				
				// handle mute/unmute
				if (muted) {
					mute()
				} else {
					unmute()
				}
				music.resume()
			}
		}
		
		// display an item
		protected function displayItem() {
		
			// get elements and related resources	
			var elements:Array = currentItem.element	
			var externalData:Object = aL.getData(currentItem)
		
			// clean content layer
			cleanContent()
			
			// set a timer for loading next element
			loadNextTimer = Run.after(currentItem.duration,nextItem)
			// if paused, pause the timer
			if (paused || (playlist && playlist.visible) ) Run.pause(loadNextTimer)
			
			// change soundtrack and backgrounds
			changeSoundtrack(externalData)
			changeBackgrounds(externalData)
			
			// if not muted and sfx defined, play it
			if (!muted && sfx && currentItem.sfx) {
				Sfx.play(sfx[currentItem.sfx.type],currentItem.sfx.volume/100,this)
			}
			
			// no elements ? do nothing
			if (!elements) return
			
			
			var i:uint = 0;
			var max:uint = elements.length
			var element:Object
		
			var eff:Effect
			var scaler:Object
		
			for (;i<max;i++) {
				element = elements[i]
				target = undefined
				
				// create the element (text or image)
				if (element.type == "image") {
					target = externalData.element[i]
				} else {
					textRenderer.maxWidth = element.width
					textRenderer.maxHeight = element.height
					textRenderer.content("<"+element.type+">" + element.content + "</"+element.type+">")
					target = textRenderer
				}
				if (!target) continue;
				// autocrop
				target = new Bitmap(Crop.auto(target))
				
				// apply filters
				target = bitfade.filters.Filter.apply(target,element.effect,true)
				
				target.alpha = 0
				
				// create the effect
				eff = bitfade.effects.cinematics.OutlineHit.create(target)
				
				// handle the link, if defined
				if (element.link) {
					eff.name = i.toString() 
					eff.buttonMode = true
				}
				
				// if shake is true, add the effect at ends
				if (element.shake) {
					eff.onComplete(shake)
				} else if (element.link) {
					// if link defined, handle it
					eff.onComplete(addIdToTarget)
				}
				
				// set effect paramenters
				eff.actions("wait",element.delay)
				eff.actions("oulineFadeIn",element.duration)
				eff.start(w,h,{style:element.style,flyBy: element.flyBy})
			
				// compute effect position
				scaler = Geom.getScaler("none",element.align.w,element.align.h,element.group ? element.width : w,element.group ? element.height : h,eff.realWidth,eff.realHeight)
				
				eff.x = int(scaler.offset.w + element.offset.w - Cinematic(eff).offset.x)
				eff.y = int(scaler.offset.h + element.offset.h - Cinematic(eff).offset.y)
				
				// add the effect
				contentLayer.addChild(eff)
				
			}
			
			
			
		}
		
		// add a sprite to handle the link
		protected function addIdToTarget(current:Effect = null):void {
			var linkHolder:Sprite = new Sprite()
			linkHolder.addChild(current.target)
			linkHolder.name = current.name
			linkHolder.buttonMode = linkHolder.useHandCursor = true
			current.target = linkHolder
		}
		
		// playing effect has ended, add shake effect
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
		
		// check item index
		protected function checkItemIdx() {
			
			// clear existing timer
			loadNextTimer = Run.reset(loadNextTimer)
			
			if (timerControl) timerControl.pos(0)
			
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
				return
			}
			
			// load next item
			currentItem = items[currentItemIdx]
			
			showLoadingLayer()
			
			gotData = false
			
			if (aL.ready(currentItem)) {
				assetReady()
			} else {
				controller()
			}
		}
		
		
		// build layers
		override protected function build():void {
		
			if (!scrollRect) scrollRect = new Rectangle(0,0,w,h)
		
			// create the textfield for texts
			textRenderer = new bitfade.ui.text.TextField({
				styleSheet:	conf.style.text,
				maxWidth: w*3/6,
				maxHeight: h,
				thickness:	0,
				sharpness:  0
			})
			
			// create layers
			backgroundLayer = new Sprite()
			contentLayer = new Sprite()
			
			
			controlLayer = new Sprite();
			controlLayer.visible = false
			overlayLayer = new Sprite();
			topLayer = new Sprite()
			
			topLayer.mouseEnabled = false
			
			// hide them for now
			contentLayer.visible = backgroundLayer.visible = false
			
			addChild(backgroundLayer)
			addChild(contentLayer)
			addChild(controlLayer)
			addChild(overlayLayer)
			addChild(topLayer)
			
			if (conf.backgrounds.layer == "top") swapChildren(backgroundLayer,contentLayer)
			
			// if we have a playlist, create it
			if (playlistConf) {
				playlistConf.caption = new XMLNode(1,"")
			
				// set playlist caption style = our caption style
				playlistConf.style.text = new XMLNode(3,conf.style.text)
				playlistConf.style.@type = conf.style.global
				
				// no external font loading for playlist coz we do this in player
				playlistConf.external.@font = ""
				
				// start as hidden
				playlistConf.@visible = false
				
				var playlistHeight:uint = parseInt(playlistConf.@height)
				playlistHeight = playlistHeight > 20 ? playlistHeight : 82
				
				playlist = new bitfade.media.preview.playlist.Chooser(w,playlistHeight,playlistConf)
				playlist.y = h-playlistHeight
				playlist.clickHandler(playlistClick,true)
				
				
				bitfade.utils.Events.add(playlist,[
					MouseEvent.ROLL_OUT
				],evHandler,this)
				
				if (playlistConf.@show != "always") {
					playlistArea = new Empty(w,20,true)
					playlistArea.name = "playlistArea"
					playlistArea.y = h - 20			
					controlLayer.addChild(playlistArea)
				} 
								
				controlLayer.addChild(playlist)	
				
				if (playlistConf.@show == "always") playlist.show()
				
				playlist.name = "playlist"
				
			}
			
			if (conf.controls.enabled && playlistConf.@show != "always") buildControls()
			
			bitfade.utils.Events.add(this,[
					MouseEvent.MOUSE_DOWN,
					MouseEvent.MOUSE_OVER,
					MouseEvent.MOUSE_OUT
			],evHandler)
				
			player = new MiniPlayer(w,h)
			player.visible = false
			player.alpha = 0
			
			bitfade.utils.Events.add(player,[PlayerEvent.PLAY,PlayerEvent.CLOSE],playerEventHandler,this)
			
			overlayLayer.addChild(player)
			
			//loading = new bitfade.ui.spinners.loaders.Layer(w,h,conf.style.color)
			
			topLayer.addChild(loading)
			
		}
		
		// build ui controls
		protected function buildControls() {
		
			var offset:uint = 0
			var spacing:uint = 18
		
			// set the style
			bitfade.ui.icons.BevelGlow.setStyle(conf.style.global,[conf.style.global == "light" ? 0x606060 : -1,conf.style.color])
			
			controlsHolder = new Sprite();
			controlsHolder.blendMode = "layer"
			controlsHolder.name = "controlsHolder"
			controlsHolder.alpha = 0.3
			
			//controlLayer.addChild(controlsHolder)
			controlLayer.addChildAt(controlsHolder,0)
				
			// add menu button, if we habe playlist
			if (playlist) {
				menuControl = new bitfade.ui.icons.BevelGlowText("menu","MENU",16,42,false)
				offset += menuControl.width + 4
				controlsHolder.addChild(menuControl)
			}	
			
			// add volume
			volumeControl = new bitfade.ui.icons.BevelGlow("volume","volume")
			volumeControl.x = offset
			offset += spacing
			controlsHolder.addChild(volumeControl)
			
			// add pause
			pauseControl = new bitfade.ui.icons.BevelGlow("pause","pause")
			pauseControl.x = offset
			offset += spacing-4
			controlsHolder.addChild(pauseControl)
			
			// add previous
			prevControl = new bitfade.ui.icons.BevelGlow("prev","prev")
			prevControl.x = offset
			offset += spacing
			controlsHolder.addChild(prevControl)
			
			// add next
			nextControl = new bitfade.ui.icons.BevelGlow("next","next")
			nextControl.x = offset
			offset += spacing
			controlsHolder.addChild(nextControl)
			
			// add the slider (countdown for next slide)
			Slider.setStyle(conf.style.global,[-1,-1,-1,conf.style.color,-1,-1,0xEEEEEE,0xA0A0A0,0xE0E0E0])
			
			timerControl = new Slider(controlsHolder.width,1,1)
			timerControl.y = (controlsHolder.height + 2)
			timerControl.mouseEnabled = false
			timerControl.mouseChildren = false
			
			timerControl.alpha = 0.8
			
			// position controls
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
			gfx.beginFill(conf.style.global == "light" ? 0xFFFFFF : 0,.3) 
			gfx.drawRoundRect(-4,-4,controlsHolder.width,controlsHolder.height,8,8)
			gfx.endFill()
			
			bitfade.utils.Events.add(controlsHolder,[
					MouseEvent.ROLL_OVER,
					MouseEvent.ROLL_OUT
			],evHandler,this)
			
			Run.every(Run.FRAME,showTimer)
			
			if (playlist) {
				playlistArea.width = w - controlsHolder.width
			}

		}
		
		// update the timer slider
		protected function showTimer() {
			if (loadNextTimer && !paused && !(playlist && playlist.visible)) {
				var now:Number = getTimer()
				var pos:Number = Math.max(0,Math.min(1,1-(loadNextTimer.runAt-now)/(currentItem.duration*1000)))
				timerControl.pos(pos)
			}
		}
		
		// show/hide playlist
		protected function showPlaylist(show:Boolean = true) {
			if (show) {
				playlist.show()
				if (controlsHolder) FastTw.tw(controlsHolder).alpha = 0
				Run.pause(loadNextTimer)
			} else {
				playlist.hide()
				if (controlsHolder) FastTw.tw(controlsHolder).alpha = 0.3
				if (!paused) {
					Run.resume(loadNextTimer)
				}
			}
		}
		
		// resume timer
		public function resumeTimer() {
			paused = true
			pauseTimerToggle()
		}
		
		// pause timer
		public function pauseTimer() {
			paused = false
			pauseTimerToggle()
		}
		
		// toggle pause/resume timer
		public function pauseTimerToggle() {
			paused = !paused
			if (loadNextTimer) {
				if (paused) {
					Run.pause(loadNextTimer)
				} else {
					Run.resume(loadNextTimer)
				}
			
			}
			if (pauseControl) pauseControl.over(paused)
		}
		
		// mute
		public function mute() {
			muted = false
			muteToggle()
		}
		
		// unmute
		public function unmute() {
			muted = true
			muteToggle()
		}
		
		// toggle mute/unmute
		public function muteToggle() {
			muted = !muted
			if (music) music.volume(muted ? 0 : musicVolume)
			if (sfx) Sfx.volumeAll(muted ? 0 : musicVolume/100,this)
			if (volumeControl) volumeControl.over(!muted)
		}
		
		// pause component
		public function pause() {
			pauseTimer()
			for (var id:* in backgrounds) {
				backgrounds[id].pause()
			}
			
			for (var i:uint=0;i<contentLayer.numChildren;i++) {
				if (contentLayer.getChildAt(i) is Effect) Effect(contentLayer.getChildAt(i)).pause()
			}
			
			if (music) music.fadePause()
		}
		
		// resume component
		public function resume() {
			if (!wasPaused) resumeTimer()
			for (var id:* in backgrounds) {
				backgrounds[id].resume()
			}
			
			for (var i:uint=0;i<contentLayer.numChildren;i++) {
				if (contentLayer.getChildAt(i) is Effect) Effect(contentLayer.getChildAt(i)).resume()
			}
			
			if (music) music.fadeResume()
		}

		// handle ui events
		protected function evHandler(e:MouseEvent) {
			var id:String = e.target.name
			var mouseOver:Boolean
			
			switch (e.type) {
				case MouseEvent.MOUSE_OVER:
				case MouseEvent.MOUSE_OUT:
					mouseOver = (e.type == MouseEvent.MOUSE_OVER)
					// handle over effect
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
					} else if (!player.visible && e.target.buttonMode && (!(e.target is Effect))) {
						if (mouseOver) {
							wasPaused = paused
							pauseTimer()
							// create the over effect for element
							var eff:Effect = bitfade.effects.cinematics.Over.create(e.target)	
							eff.actions("over",.5)				
							eff.start(w,h,{flyBy: "none"})
							contentLayer.addChild(eff)
						} else {
							if (!wasPaused) resumeTimer()
						}
						
						
					}
					
					switch (id) {
						case "playlistArea":
							// show playlist
							if (mouseOver) showPlaylist()
						break;
					}
					
				break;
				case MouseEvent.MOUSE_DOWN:
					switch (id) {
						case "menu":
							showPlaylist()
						break;
						case "next":
						case "prev":
							advance(id)
						break;
						case "pause":
							pauseTimerToggle()
						break;
						case "volume":
							muteToggle()
						break;
						default:
							// load link
							if (e.target.parent == contentLayer) {
								loadUrl(parseInt(id))
							}
					
						break;
					}
					
				break;
				case MouseEvent.ROLL_OVER:
				case MouseEvent.ROLL_OUT:
					mouseOver = (e.type == MouseEvent.ROLL_OVER)
					switch (id) {
						case "playlist":
							if (playlistConf.@show != "always" && !mouseOver && !loading.visible) {
								showPlaylist(false)
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
		
		// advance slide
		public function advance(dir:String = "next"):void {
			currentItemIdx += (dir == "next" ? +1 : -1)
			checkItemIdx()
		}
		
		// handle player events
		protected function playerEventHandler(e:PlayerEvent) {
			switch (e.type) {
				case PlayerEvent.PLAY:
					if (player.alpha == 0) {
						pause()
						showLoadingLayer(false)
						player.show()
					}
				break;
				case PlayerEvent.CLOSE:
					resume()
				break;
			}
		}
		
		// show/hide loading layer
		protected function showLoadingLayer(s:Boolean = true):void {
			if (s) {
				loading.show()
			} else {
				loading.hide()
			}
		}
		
		// load external resource (video/label/url)
		public function loadUrl(id:uint = 0) {
			var url:String = currentItem.element[id].link
			var target:String = currentItem.element[id].target
			
			switch (target) {
				case "video":
					wasPaused = paused
					if (!paused) pauseTimer()
					showLoadingLayer()
					player.load(url)
				break;
				case "label":
					switch (url) {
						case "next":
						case "prev":
							advance(url)
						break;
						default:
							goto(labels[url])
					}
				break;
				default:
					ResLoader.openUrl(url,target)
			}
			
		}
		
		// load selected playlist slide
		protected function playlistClick(item:Object) {
			goto(parseInt(item.key))
		}
		
		// goto specific slide
		public function goto(id:uint) {
			currentItemIdx = id
			checkItemIdx()
		}
		
		// init slideshow display
		override protected function display():void {
			super.display()
			background();
		}
		
		// destroy slideshow
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