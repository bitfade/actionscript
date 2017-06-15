/*

	Dna particles intro

*/
package bitfade.intros {
	
	import flash.display.*
	import flash.system.ApplicationDomain
	import flash.media.Sound
	import flash.geom.*
	import flash.events.*
	
	
		
	import bitfade.intros.Intro
	import bitfade.utils.*
	import bitfade.data.*
	import bitfade.easing.*
	import bitfade.effects.*
	import bitfade.effects.cinematics.*
	import bitfade.intros.backgrounds.*
	import bitfade.filters.*
	
	public class DnaParticles extends bitfade.intros.Intro {
	
		protected var whoosh:Class
		
		protected var textTarget:Bitmap
		
		protected var firstRun:Boolean = true
		
		protected var particles:bitfade.intros.backgrounds.DnaParticles
		
		protected var runNextTimer:RunNode
		protected var nextTime:Number = 0
		
		// constructor
		public function DnaParticles(...args) {
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			
			// set defaults
			defaults.external = {
				library: "library|resources/audio/soundFxLibrary.swf"
			}
			
			// intro defaults
			defaults.background.color = 0x78808B
			defaults.background.color2 = 0x000020
			
			defaults.images = {
				style: "dark",
				width: 424,
				height: 240,
				scale: "fit"
			}
			
			defaults.sfx = {
				volume:80
			}
			
			defaults.intro.fast = false
			
			defaults.particles = {
				enabled:true,
				glow:true,
				blendMode: "add",
				minSize: 2,
				maxSize: 64,
				maxAlpha: 1,
				margin: 140,
				solid:false,
				start:"",
				color: 0
			}
			
			itemDefaults.thumb = true
			itemDefaults.hdr = true
			itemDefaults.zoom = "in"
			itemDefaults.rotation = 30
			
			itemDefaults.effect = "clean,glow"
			
			configName = "intro"
			
		}
		
		// add missing values
		override protected function addDefaults():void {
			
			
			var item:Object
			var last:String = "right"
			
			// set default values and compute timings
			for each (item in items) {
				if (!item.burst) {
					if (item.position) {
						item.burst = item.position == "left" ? "right" : "left"
					} else {
						// set burst to opposite of position
						item.burst = last == "left" ? "right" : "left"
					}
					last = item.burst
				}
				
				if (!item.rotation) {
					// default rotation, if not already set
					switch (item.position) {
						case "left" : 
							item.rotation = -30
							break;
						case "center":
							item.rotation = 0
							break;
						default:
							item.rotation = 30
					}
				}
				
			}
			
			super.addDefaults()
			
			// split effects
			for each (item in items) {
				item.effect = item.effect.split(",")
			}
			
			// handle the start with starfield case
			if (items[0].burst == "starfield") conf.particles.start = "starfield"
		
		}
		
		// resize images assets when they are loaded
		override protected function transformAsset(asset:DisplayObject) {
			if (asset is Bitmap) {
				var tw: uint = conf.images.width
				var th: uint = conf.images.height
			
				// auto crop
				var cropped:BitmapData = Crop.auto(asset)
				
				Gc.destroy(Bitmap(asset).bitmapData)
				
				var mat:Matrix = Geom.getScaleMatrix(Geom.getScaler(conf.images.scale,"center","center",tw,th,cropped.width,cropped.height))
				
				// scale
				var scaled:BitmapData = Snapshot.take(cropped,Bdata.create(tw,th),0,0,mat)
				
				cropped = Gc.destroy(cropped)
				
				Bitmap(asset).bitmapData = scaled
			}
			
			
			return asset
		}
		
		
		// asset is loaded, process it
		override protected function assetReady() {
			
			gotData = true
			
			target = textTarget = undefined
			
			// external image
			if (currentItem.resource) {
			
				target = aL.getData(currentItem)
				
				var newTarget:Bitmap 
				
				// apply effects
				if (currentItem.thumb) {
					newTarget= new Bitmap(bitfade.filters.Thumb.apply(target,conf.images.style == "light" ? "default.light" : "default.dark"))
					//currentItem.hdr = true
				} else {
					newTarget= new Bitmap(bitfade.filters.Glow.apply(target))
					currentItem.hdr = false
				}
				
				// remove a target only if we are sure it will be reloaded
				// reloading won't happen if assetLoader has cached all is items, in this
				// case, don't call destroy on target (which is a reference to aL cached item)
				if (!aL.fullCached) {
					Gc.destroy(target)
				}
				target = newTarget
			
			}
			
			// text
			if (currentItem.caption) {
				textRenderer.content(currentItem.caption[0].content)
				textTarget = new Bitmap(Crop.auto(textRenderer))
				
				// apply effects
				for each (var effectType:String in currentItem.effect) {
					switch (effectType) {
						case "clean":
							textTarget= new Bitmap(bitfade.filters.Clean.apply(textTarget))
						break;
						case "glow":
							textTarget= new Bitmap(bitfade.filters.Glow.apply(textTarget))
						break;
						case "steel":
							textTarget = new Bitmap(bitfade.filters.Steel.apply(textTarget))
						break;
					}
				}
				
			}
			
			controller()
			displayItem()
			
		}
		
		// called when external resources are loaded
		override protected function resourcesLoaded(content:* = null):void {
			if (content is Array && content.length > 0) {
				var node:*
				while (node = content.pop()) {
					if (node is ApplicationDomain) break;
				}
				// get sound effect
				if (node) {
					if (node.hasDefinition("soundFxLibrary_sfx_Whoosh")) {
						whoosh = node.getDefinition("soundFxLibrary_sfx_Whoosh")
					}
				}
			}
			super.resourcesLoaded(content)
		}
		
		// start intro
		override protected function start() {
			super.start()
			bitfade.utils.Events.add(this,MouseEvent.CLICK,clickHandler)
			runNextTimer=Run.every(Run.FRAME,runNext)
		}
		
		protected function clickHandler(e:Event) {
			var id:String = e.target.name
			if (id && items[id]) {
				var link:String = items[id].link
				if (link) ResLoader.openUrl(items[id].link,items[id].linkTarget)
			}
		}
		
		// run next item
		protected function runNext() {
			if (nextTime > 0 && time >= nextTime) {
				finished()
			}
		}
		
		// show current item
		override protected function displayItem() {
		
			
			var imageEffect:Effect 
			var textEffect:Effect 
			var currentEffect:Effect
			
			var effects:Array = []
			
			// image effect
			if (target) {
				imageEffect = bitfade.effects.cinematics.HDR.create(target).onComplete(cleanEffect)
				imageEffect.ease = Sine.In
				effects.push(imageEffect)
			}
			
			// text effect
			if (textTarget) {
				textEffect = bitfade.effects.cinematics.HDR.create(textTarget).onComplete(cleanEffect)
				textEffect.ease = Sine.In
				effects.push(textEffect)
			}
			
			if (currentItem.link) {
				for each (currentEffect in effects) {
					currentEffect.name = currentItemIdx.toString()
					currentEffect.buttonMode = true
					
				}
			}
			
			
			
			
			// compute delay
			var delay:Number = currentItem.start - time
			
			if (delay > 0.2) {
				for each (currentEffect in effects) {
					currentEffect.target.alpha = 0
					currentEffect.actions("wait",delay)
				}
				delay = 0
			} 
			
			
			// compute effect duration and wait time
			var duration:Number = Math.max(0,currentItem.duration + delay)
			var wait:Number
			var fadeOut:Number = 0
			
			wait = Math.min(duration,currentItem.wait)
			
			if (wait > 0) {
				duration = Math.max(0,duration-wait)
			}
			
			// next item run time
			nextTime = time+duration
				
			// set effect
			for each (currentEffect in effects) {
				if (duration > 0) {
					currentEffect.target.alpha = 0
					currentEffect.actions("wait",0.5)
					currentEffect.actions("glow",duration+0.2)
				} else {
					currentEffect.target.alpha = 1
				}
			}
		
		
			// set background gradient and burst
			if (particles) {
				particles.gradient(currentItem.color || "oceanHL")
				if (currentItem.burst != "false") {
					if (firstRun) {
						firstRun = false
					} else {
						particles.burst(currentItem.burst)
						// play sfx
						if (conf.sfx.volume > 0) Sfx.play(whoosh,conf.sfx.volume/100,this)
					
					}
				}
			}
			
			var isText:Boolean
			
			if (wait == 0 && duration == 0 && fadeOut == 0) {
				// too late for current item, jump to next
				finished(effects[0])
				
			} else {
				
				for each (currentEffect in effects) {
					isText = currentEffect == textEffect
					
					var hdr:Boolean = currentItem.hdr
					 
					if (isText || conf.intro.fast) hdr = false
					
					
					// compute effect values
					var angle:Number = 0
					var zFrom:Number = 0
					var zTo:Number = 0
					
					if (!conf.intro.fast) {
						angle = currentItem.rotation
						
						switch (currentItem.zoom) {
							case "in" :
								zFrom = 0
								zTo = 200
								break;
							case "out":
								zFrom = 200
								zTo = 0
						}
					}
					
					// start the effect
					currentEffect.start(w,h,{angle:angle,zFrom:zFrom,zTo:zTo,hdr: hdr,targetZ: (isText && imageEffect ? -50 : 0)})
					
					// add to intro
					introLayer.addChild(currentEffect)
					activeEffects[currentEffect] = true	
				}
				
				
				// here we compute effects coordinates
				for each (currentEffect in effects) {
					isText = currentEffect == textEffect
					
					var horizMargin:uint = isText ? 30 : 10
					var vertMargin: uint = effects.length == 2 ?  10 : 0
					
					var twoThird: uint = (w*2)/3
					var oneThird: uint = (w)/3
					
					
					switch (currentItem.position) {
						case "left" : 
							currentEffect.x = Math.max(horizMargin,((twoThird-currentEffect.realWidth) >> 1 ))
							break;
						case "center":
							currentEffect.x = ((w-currentEffect.realWidth) >> 1 )
							vertMargin = 30
							break;
						default:
							currentEffect.x = Math.min(((w-currentEffect.realWidth) ) - horizMargin,(oneThird+((twoThird-currentEffect.realWidth) >> 1 )))
					}
					
					currentEffect.y = ((h-currentEffect.realHeight) >> 1) - vertMargin
						
					if (isText) {
						if (imageEffect) {
							currentEffect.y = ((h-currentEffect.realHeight)  ) - vertMargin
						} 
					}
											
				}
				
				
			}
			
			
			
		}
		
		// playing effect has ended
		protected function cleanEffect(current:Effect):void {
			delete activeEffects[current]
			current.target = Gc.destroy(current.target)
		}
		
		// pause intro
		override public function pause():void {
			super.pause()
			Sfx.pauseAll(this)
			particles.pause()
		}
		
		// resume intro
		override public function resume():void {
			super.resume()
			particles.play()
		}
		
		// set background
		override protected function background():void {
		
			// create particles object
			if (conf.particles.enabled) {
				particles = new bitfade.intros.backgrounds.DnaParticles(w,h,conf.particles)		
				particles.blendMode = conf.particles.blendMode
				
				particles.mouseEnabled = false
				particles.mouseChildren = false
		
				topLayer.addChild(particles)
				if (spinner) topLayer.swapChildren(spinner,particles)
				
			}
			
			// set background
			switch (conf.background.type) {
				case "intro":
				case "gradient":
				case "default":
					back = new bitfade.intros.backgrounds.Intro(w,h,conf.background)
				break;
				case "image":
					back = new bitfade.intros.backgrounds.Image(w,h,conf.background)
				break;
			}
			
			
			super.background()
			// uncomment line to have particles on background layer
			//backgroundLayer.addChild(particles)
			
			
		}
		
		
		// set music volume
		override public function volume(...args) {
			var ratio:Number = args[0]
			var sfxRatio:Number = args[1] ? args[1] : args[0]
			
			if (!conf) return Commands.queue(this,volume,ratio,sfxRatio)
			
			conf.soundtrack.volume = ratio
			conf.sfx.volume = sfxRatio
		
			if (music) music.volume(ratio/100)
			Sfx.volumeAll(ratio/100,this)
			
		}
		
		
		// activate intro
		override protected function activate():void {
			super.activate()
			if (particles) particles.start()
		}
		
		// destroy intro
		override public function destroy():void {
			Run.reset(runNextTimer)
			if (particles) particles.destroy()
			particles = undefined
			Sfx.pauseAll(this)
			super.destroy()
		}
		
	}
}
/* commentsOK */
