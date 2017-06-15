/*
	this are helper functions used to bootstrap application
*/
package bitfade.utils { 

	import flash.events.*
	import flash.display.*
	import flash.utils.Dictionary
	
	import bitfade.core.IBootable
	
	public class Boot {
	
		public static var stage:Stage
		private static var map:Dictionary
		private static var stageFix:Boolean = false;
		
		// call this if application needs Stage to run
		public static function onStageReady(obj:IBootable,args:Array = null):void {
			if (!map) map = new Dictionary(true)
			map[obj] = {params:args}	
			bootWhenReady(obj)
		}
		
		// this checks if obj has stage
		protected static function bootWhenReady(obj:*):void {		
			if (obj.stage) {
				map[obj].whereAdded = true
				if (isReady(obj.stage)) doBoot(obj)
			} else {
				obj.addEventListener(Event.ADDED_TO_STAGE,addedToStage)
			}
			
		}
		
		// this gets called obj is added to stage
		protected static function addedToStage(e:Event):void {
			var obj:* = e.target
			obj.removeEventListener(Event.ADDED_TO_STAGE,addedToStage)
			bootWhenReady(obj)
		}
		
		// this checks if stage has not null size
		protected static function isReady(s:Stage):Boolean {
			if (s.stageWidth > 0 && s.stageHeight > 0) {
				// stage is ready
				stage = s		
				return true
			} else {
				// EEK! stage is 0 sized
				if (!stageFix) {
					stageFix = true
					s.scaleMode = "noScale";
					s.align = "TL";
					s.addEventListener(Event.RESIZE, checkResize);
				}
				return false
			}
			
		}
		
		// this gets called when stage is resized until valid size is found
		protected static function checkResize(e:Event):void {
			var s:* = e.target
			
			if (s.stageHeight > 0 && s.stageWidth > 0) {
				stageFix = false
    			s.removeEventListener(Event.RESIZE, checkResize);
    			stage = s
    			for (var obj:* in map) doBoot(obj)
    		} 
  		}
		
		// boot the object
		protected static function doBoot(obj:*):void {
			var saved:* = map[obj]
			if (saved.whereAdded) {
				delete map[obj]
				obj.boot.apply(null,saved.params)
			}
		}

		
	}
}
/* commentsOK */