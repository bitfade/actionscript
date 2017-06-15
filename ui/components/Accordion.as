/*

	Accordion Component

*/
package bitfade.ui.components {
	
	import flash.display.*
	
	import bitfade.core.components.Xml
	import bitfade.ui.accordion.*
	import bitfade.utils.*
	
	public class Accordion extends bitfade.core.components.Xml {
	
		protected var items:Object
		public var main:AccordionManager;
		protected var cover:DisplayObject;
	
		// constructor
		public function Accordion(...args) {
			bitfade.utils.Boot.onStageReady(this,args)
		}
	
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			
			configName = "accordion"
		}
		
		// configure the intro
		override protected function configure():Boolean {
			items = conf.item
			if (items && items is Array && items.length > 0) {
				addDefaults()
				return true
			}
						
			// no items defined, nothing to do
			return false
			
		}
		
		// add missing values
		protected function addDefaults():void {		
		}
		
		override protected function resourcesLoaded(content:* = null):void {
			if (content && content.background) cover = content.background
			super.resourcesLoaded(content)
		}
		
		// build layers
		override protected function build():void {
			if (cover) addChild(cover)
			main = new AccordionManager(w,h,conf.item[0])
			addChild(main)
		}
		
		override public function resize(nw:uint = 0,nh:uint = 0):void {
			super.resize(nw,nh)
			if (main) main.resize(nw,nh)
		}
		
		// destroy intro
		override public function destroy():void {
			super.destroy()
		}
		
		public function advance(n:int,absolute:Boolean=false):void {
			if (main) main.advance(n,absolute)
		}
	
	}
}
/* commentsOK */