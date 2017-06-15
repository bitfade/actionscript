/*

	Back light intro

*/
package bitfade.intros {
	
	import flash.display.*
		
	import bitfade.intros.Intro
	import bitfade.intros.backgrounds.*
	import bitfade.utils.*
	import bitfade.data.*
	import bitfade.easing.*
	import bitfade.effects.*
	import bitfade.effects.cinematics.*
	
	
	
	public class Backlight extends bitfade.intros.Intro {
	
		// constructor
		public function Backlight(...args) {
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// add missing values
		override protected function addDefaults():void {
					
			super.addDefaults()
			
			if (!conf.intro.loop) {
				items[items.length-1].fadeOut = 0
			}
		
		}
		
		override protected function displayItem() {
		
			// create the effect
			var eff:Effect = bitfade.effects.cinematics.Backlight.create(target).onComplete(finished)
			
			// compute delay
			var delay:Number = currentItem.start - time
			
			var dl:Number = delay
			
			if (delay > 0.2) {
				eff.target.alpha = 0
				eff.actions("wait",delay)
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
			
			
			if (duration > 0) {
				eff.actions("light",duration)
			} else {
				target.alpha = 1
			}
			
			
			
			// compute fadeOut
			if (wait > 0) {
				currentItem.fadeOut = 0
				fadeOut = isLast ? 0 : Math.min(0.2,wait) 
				wait -= fadeOut
				if (wait > 0) eff.actions("wait",wait)
				if (fadeOut > 0) eff.actions("fadeOut",fadeOut)
			}
			
				
			// set background gradient and burst
			if (back) {
				back.gradient(currentItem.color || "oceanHL")
				if (currentItem.burst) back.burst()
			}
			
			
			if (wait == 0 && duration == 0 && fadeOut == 0) {
				// too late for current item, jump to next
				finished(eff)
			} else {
				// start the effect
				eff.start(w,h,currentItem)
			
				// compute position
				eff.x = ((w-eff.realWidth) >> 1) - Cinematic(eff).offset.x
				eff.y = ((h-eff.realHeight) >> 1) - Cinematic(eff).offset.y
			
			
				// add the effect
				introLayer.addChild(eff)
			
				activeEffects[eff] = true	
			}
			
		}
		
		// destroy intro
		override public function destroy():void {
			super.destroy()
		}
		
		// load intro background
		override protected function background():void {
		
			switch (conf.background.type) {
				case "gradient":
				case "default":
					back = new bitfade.intros.backgrounds.Intro(w,h,conf.background)
				break;
				case "image":
					back = new bitfade.intros.backgrounds.Image(w,h,conf.background)
				break;
				case "spectrum":
					back = new bitfade.intros.backgrounds.Spectrum(w,h,conf.background)
				break;
			}
			
			super.background()
			
		}
		
		
	}
}
/* commentsOK */