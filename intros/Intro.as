/*

	Base class for intros, has common methods

*/
package bitfade.intros {
	
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	import flash.geom.*
	import flash.utils.*
	
	import bitfade.core.components.Xml
	import bitfade.utils.*
	import bitfade.ui.text.*
	import bitfade.media.streams.*
	import bitfade.filters.*
	import bitfade.intros.backgrounds.*
	import bitfade.effects.*
	
	
	public class Intro extends bitfade.core.components.Xml {
	
		// status codes
		public static const STOPPED:uint = 0
		public static const RUNNING:uint = 1
		public static const LOADING:uint = 2
	
		protected var status:uint = STOPPED
	
		// items
		protected var items: Array
		
		// default item values
		protected var itemDefaults:Object = {
			start: -1,
			burst: "default",
			duration: 3,
			wait:0,
			embedFonts: false	
		}
		
		// current item
		protected var currentItem:Object
		protected var currentItemIdx:uint = 0
		
		// position
		protected var position:Point
		
		// asset loader
		protected var aL:AssetLoader
		
		// target
		protected var target:DisplayObject
		
		// soundtrack
		protected var music:bitfade.media.streams.Audio
		
		// background
		protected var back: bitfade.intros.backgrounds.Background
		
		// textField to render text
		protected var textRenderer:bitfade.ui.text.TextField
		
		// intro layers
		protected var topLayer:Sprite
		protected var introLayer:Sprite
		protected var backgroundLayer:Sprite
		
		// running effects
		protected var activeEffects:Dictionary 
		
		// data semaphore
		protected var gotMusic:Boolean = false
		protected var gotData:Boolean = true
		
		// needed for compute pause timings
		protected var pauseStart:uint = 0
		protected var pausedFor:uint = 0
		protected var musicLoopOffset:Number = 0
		
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			
			// set defaults
			defaults.style = {
			}
			
			defaults.intro = {
				fadeIn:0.5,
				fadeOut:0.5,
				loop:false,
				onComplete:""
			}
			
			defaults.soundtrack = {
				resource: "",
				volume: 100,
				loop:false,
				offset:0
			}
			
			defaults.background = {
				type: "none"
			}
			
			configName = "intro"
			
		}
		
		// configure the intro
		override protected function configure():Boolean {
			
			items = conf.item
			
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
			var start:Number = 0
			var duration:Number = 0
			var previous:Object
			var item:Object
			
		
			// set default values and compute timings
			for each (item in items) {
				item = Misc.setDefaults(item,itemDefaults)
				
				if (item.start >= 0) {
					if (previous) {
						previous.duration = item.start-previous.start
					}
				} else {
					item.start = start
					start += item.duration

				}
				previous = item
			}
			
			if (!conf.intro.loop) {
				if (items[0].start == 0) items[0].fadeIn = 0
			}
		
		}
		
		// start loading external assets
		protected function loadAssets():void {
			currentItemIdx = 0
			currentItem = items[currentItemIdx]
			aL = new AssetLoader(items,loadMusic,transformAsset)
			aL.start()
		}
		
		protected function transformAsset(asset:DisplayObject) {
			return asset
		}
		
		// get current intro time
		public function get time():Number {
			var t:Number = (music && !music.stopped) ? music.time : (getTimer()-pausedFor)/1000
			if (music) t += musicLoopOffset
			return t
		}
		
		// load soundtrack
		protected function loadMusic():void {
			if (conf.soundtrack.resource) {
				music = new bitfade.media.streams.Audio()
				// add event listeners
				bitfade.utils.Events.add(music,StreamEvent.GROUP_PLAYBACK,musicEventHandler,this)
				music.load(conf.soundtrack.resource,false)
				
				if (conf.intro.fadeIn == 0) {
					music.volume(conf.soundtrack.volume/100)
				} else {
					music.volume(0)
				}
				
			} else {
				gotMusic = true
				controller()
			}
		}
		
		// handle soundtrack events
		protected function musicEventHandler(e:StreamEvent):void {
			gotMusic = true
			
			switch (e.type) {
				case StreamEvent.BUFFERING:
					gotMusic = e.value < 1 ? false : true
				case StreamEvent.PLAY:
				case StreamEvent.RESUME:
					controller()
				break;
				case StreamEvent.STOP:
					if (conf.soundtrack.loop) {
						// restart music playback
						musicLoopOffset += music.duration
 						music.seek(0)
 						music.resume()
					} 
					
				break
			}
			
		}
		
		// hanle intro status changes
		protected function controller() {
		
			var ready:Boolean = gotMusic && gotData
		
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
						pause()
					}
				break;
				case LOADING:
					if (ready) {
						status = RUNNING
						resume()
					}
				break;
			}
		
			if (status == LOADING) {
				spinner.show()
			} else {
				spinner.hide()
			}
		
		}
		
		// called when loading asset is ready
		protected function assetLoaded():void {
			if (!gotData) {
				assetReady()
			}
		}
		
		// pause intro
		public function pause():void {
			pauseStart = getTimer()
			if (music) music.pause()
			if (back) back.pause()
			for (var effect in activeEffects) effect.pause()
			
		}
		
		// resume intro
		public function resume():void {
			for (var effect in activeEffects) effect.resume()
			if (back) back.play()
			if (music) music.play()
			pausedFor += (getTimer()-pauseStart)
		}
		
		// begin playback
		protected function activate():void {
			pausedFor = getTimer()
			if (back) {
				back.gradient(currentItem.color,true)
				back.start()
			}
			aL.readyCallBack = assetLoaded
			assetReady()
			alpha = 0
			introLayer.visible = backgroundLayer.visible = true
			start()
		}
		
		// asset is loaded, process it
		protected function assetReady() {
			
			gotData = true
			
			if (currentItem.resource) {
				// external image
				target = aL.getData(currentItem)
			} else {
				// text content
				textRenderer.content(currentItem.caption[0].content)	
				target = textRenderer
			}
			
			// add effect (if defined)
			if (currentItem.effect) {
				var newTarget:Bitmap = new Bitmap(bitfade.filters.OutlineBlack.apply(target))
				Gc.destroy(target)
				target = newTarget
			}
			
			controller()
			displayItem()
			
		}
		
		protected function displayItem() {
		}
		
		// build intro layers
		override protected function build():void {
		
			activeEffects = new Dictionary(true)
		
			position = new Point()
			
			textRenderer = new bitfade.ui.text.TextField({
				styleSheet:	conf.style.content,
				maxWidth: w,
				maxHeight: h,
				thickness:	0,
				sharpness:  50
			})
			
			backgroundLayer = new Sprite()
			introLayer = new Sprite()
			topLayer = new Sprite()
			
			topLayer.mouseEnabled = false
			
			
			introLayer.visible = backgroundLayer.visible = false
			
			addChild(backgroundLayer)
			addChild(introLayer)
			addChild(topLayer)
			
			topLayer.addChild(spinner)
			
						
		}
		
		// init intro display
		override protected function display():void {
			super.display()
			background();
		}
		
		// playing effect has ended
		protected function finished(current:Effect = null):void {
			if (current) delete activeEffects[current]
			if (!conf.intro.loop && currentItemIdx == (items.length-1)) {
				// if last item, keep the target
				if (current) {
					target.alpha = 1
					introLayer.addChild(target)
					target.x = current.x
					target.y = current.y
				}
			} else {
				//target = Gc.destroy(target)
			}
			nextItem()
		}
		
		
		// load next item
		protected function nextItem() {
			currentItemIdx++
			if (currentItemIdx > items.length) return
			
			if (currentItemIdx == items.length && conf.intro.loop) { 
				// loop intro
				
				
				currentItemIdx = 0
				musicLoopOffset = 0
				
				
				if (music) {
					//gotMusic = false
					music.seek(0)
					if (music.stopped) music.resume()
				}
				
				pausedFor = getTimer()
				//return
			}
			
			getNextItem()	
			
			
		}
		
		protected function getNextItem() {
			if (currentItemIdx == items.length) {
				// last item
				end()
				return
			}
			
			// load next item
			currentItem = items[currentItemIdx]
			spinner.show(0.1)
			
			gotData = false
			
			if (!currentItem.resource || aL.ready(currentItem)) {
				assetReady()
			} else {
				controller()
			}
		}
		
		// call fadeIn
		protected function start() {
			if (conf.intro.fadeIn > 0.1) {
				Run.every(Run.FRAME,fadeIn,uint(conf.intro.fadeIn*stage.frameRate+.5),0,true)
			} else {
				alpha = 1
			}
			
		}
		
		// call fadeOut
		protected function end() {
			Run.every(Run.FRAME,fadeOut,uint(conf.intro.fadeOut*stage.frameRate+.5),0,true)
		}
		
		// return true if last item
		protected function get isLast():Boolean {
			return !conf.intro.loop && currentItemIdx == items.length - 1
		}
		
		// fadeIn intro
		protected function fadeIn(ratio:Number) {
			alpha = ratio
			if (music) music.volume(ratio*conf.soundtrack.volume/100)
		}
		
		// fadeOut intro
		protected function fadeOut(ratio:Number) {
			ratio = 1-ratio
			alpha = ratio
			if (music) music.volume(ratio*conf.soundtrack.volume/100)
			if (ratio == 0) callExternal()
		}
		
		// call external link
		protected function callExternal():void {
			// load external page/movie
			if (conf.intro.onComplete && conf.intro.onComplete != "") {
				ResLoader.openUrl(conf.intro.onComplete)
			}
			destroy()
			
		}
		
		// set music volume
		public function volume(...args) {
			var ratio:Number = args[0]
			
			if (!conf) return Commands.queue(this,volume,ratio)
			
			conf.soundtrack.volume = ratio
			
			if (music) music.volume(ratio/100)
			
		}
		
		// destroy intro
		override public function destroy():void {
			if (back) {
				back.destroy()
				back = undefined
			}
			if (music) {
				music.destroy()
				music = undefined
			}
			
			for (var effect in activeEffects) effect.destroy()
			
			super.destroy()
		}
		
		// load intro background
		protected function background():void {
			spinner.show()
			if (back) {
				backgroundLayer.addChild(back)
				back.onReady(loadAssets)
			} else {
				loadAssets()
			}
		}
	
	}
}
/* commentsOK */