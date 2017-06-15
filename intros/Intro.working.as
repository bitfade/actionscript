/*

	Base class for intros, has common methods

*/
package bitfade.intros {
	
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	import flash.geom.*
	import flash.utils.*
	
	import bitfade.core.components.xml
	import bitfade.utils.*
	import bitfade.ui.text.*
	import bitfade.media.streams.*
	import bitfade.filters.*
	import bitfade.intros.backgrounds.*
	
	
	public class intro extends bitfade.core.components.xml {
	
		public static const LOADING:uint = 0
		public static const RUNNING:uint = 1
	
		// items
		protected var items: Array
		
		protected var itemDefaults:Object = {
			start: -1,
			burst: true,
			duration: 3,
			wait:0
		}
		
		protected var currentItem:Object
		protected var currentItemIdx:uint = 0
		
		protected var position:Point
		
		protected var aL:assetLoader
		protected var target:DisplayObject
		protected var status:uint = 0
		
		protected var music:bitfade.media.streams.audio
		
		protected var back: bitfade.intros.backgrounds.background
		
		protected var textRenderer:bitfade.ui.text.TextField
		
		protected var topLayer:Sprite
		protected var introLayer:Sprite
		protected var backgroundLayer:Sprite
		
		protected var activeEffects:Dictionary 
		
		protected var gotMusic:Boolean = false
		protected var gotData:Boolean = true
		
		
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			defaults.style = {
			}
		}
		
		override protected function configure():void {
			items = conf.item
			addDefaults()
		}
		
		protected function addDefaults():void {
			var start:Number = 0
			var duration:Number = 0
			var previous:Object
			var item:Object
			
		
			for each (item in items) {
				item = misc.setDefaults(item,itemDefaults)
				
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
		
		}
		
		protected function loadAssets():void {
			spinner.show()
			status = LOADING
			currentItemIdx = 0
			currentItem = items[currentItemIdx]
			aL = new assetLoader(items,loadMusic)
			aL.start()
		}
		
		protected function loadMusic():void {
			music = new bitfade.media.streams.audio()
			// add event listeners
			bitfade.utils.events.add(music,streamEvent.GROUP_PLAYBACK,musicEventHandler,this)
			music.load("resources/audio/GloriousVictoryRock30.mp3",false)
			music.volume(1)
			
		}
		
		protected function musicEventHandler(e:streamEvent):void {
			import bitfade.debug
			debug.log(e.type)
			
			switch (e.type) {
				case streamEvent.PLAY:
					activate()
				break;
				case streamEvent.BUFFERING:
					
					pause()
				break;
				case streamEvent.RESUME:
					if (status == RUNNING) {
						resume()
					}
				break
				
			}
			
		}
		
		protected function check() {
		}
		
		public function pause():void {
			trace("PAUSE")
			spinner.show(0.1)
			music.pause()
			for (var effect in activeEffects) effect.pause()
			back.pause()
		}
		
		public function resume():void {
			if (music.paused || status == LOADING) {
				trace("RESUME")
				spinner.hide()
				for (var effect in activeEffects) effect.resume()
				back.play()
				music.play()
				//if (music.paused) music.play()
				
			}
		}
		
		protected function activate():void {
			back.gradient(currentItem.color,true)
			aL.readyCallBack = assetReady
			assetReady()
			
		}
		
		protected function assetReady() {
			if (status == LOADING) {
				
				if (currentItem.resource) {
					target = aL.getData(currentItem)
				} else {
					textRenderer.content(currentItem.caption[0].content)
					target = textRenderer
				}
				
				if (currentItem.effect) {
					var newTarget:Bitmap = new Bitmap(bitfade.filters.outlineBlack.apply(target))
					Gc.destroy(target)
					target = newTarget
				}
				
				resume()
				status = RUNNING
				displayItem()
			}	
		}
		
		protected function displayItem() {
		}
		
		override protected function build():void {
		
			activeEffects = new Dictionary(true)
		
			position = new Point()
			
			textRenderer = new bitfade.ui.text.TextField({
				styleSheet:	conf.style.content,
				maxWidth: w,
				maxHeight: h,
				thickness:	-100,
				sharpness:  0
			})
			
			backgroundLayer = new Sprite()
			introLayer = new Sprite()
			topLayer = new Sprite()
			
			addChild(backgroundLayer)
			addChild(introLayer)
			addChild(topLayer)
			
			topLayer.addChild(spinner)
			
						
		}
		
		override protected function display():void {
			super.display()
			background();
			loadAssets()

		}
		
		protected function nextItem() {
			currentItemIdx++
			//if (currentItemIdx == items.length) currentItemIdx = 0
			if (currentItemIdx == items.length) return
			
			currentItem = items[currentItemIdx]
			status = LOADING
			spinner.show(0.1)
			
			if (!currentItem.resource || aL.ready(currentItem)) {
				assetReady()
			} else {
				pause()
			}
		}
		
		protected function background():void {
			/*
			import bitfade.ui.backgrounds.engines.*
			
			
			var b2:Bitmap = new Bitmap()
			
			Snapshot.take(bitfade.ui.backgrounds.engines.intro.create("dark",w,h),b2)
			*/
			
			//import bitfade.media.visuals.*
			//addChild(new bitfade.media.visuals.spectrum(w,h))
			
			
			back = new bitfade.intros.backgrounds.spectrum(w,h)
			backgroundLayer.addChild(back)
			
			back.pause()
			
			//nextItem()
		}
	
	}
}
/* commentsKO */