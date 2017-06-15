/*

	configurable gradient background

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import flash.events.*
	
	import bitfade.utils.*
	import bitfade.effects.*
	import bitfade.ui.backgrounds.engines.*
	
			
	
	public class Reflection extends Background {
	
		//protected var bMap:Bitmap
		
		public function Reflection(...args) {
			configure.apply(null,args)
		}
		
		override protected function init():void {
			super.init()
			
			Events.add(this,Event.ADDED_TO_STAGE,initReflection)
		}
		
		protected function initReflection(e:Event) {
			Events.remove(this)
			
			// create a new holder
			var target:Sprite = new Sprite()
			// save parent reference
			var p:DisplayObjectContainer = parent
			// remove us from parent
			parent.removeChild(this)
			
			// move each parent children to the new holder
			while (p.numChildren > 0) {
				target.addChild(p.getChildAt(0))
			}
			
			// add the new holder to parent 
			p.addChild(target)
			// add us to parent again
			p.addChild(this)
			
			// create and add the reflection plane
			var rPlane = new RefPlane({target:target,width:w,height:h-conf.size,alpha:50,falloff:conf.size-1,autoUpdate:true})
			rPlane.init()
			rPlane.y = h
			addChild(rPlane)
			
		}
				
	}

}
/* commentsOK */