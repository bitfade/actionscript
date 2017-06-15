/*
	this are helper functions used to reuse and set filters 
*/
package bitfade.utils { 

	import flash.filters.*
	import flash.utils.*

	public class Filter {
		
		// holds created filter
		static var _filters:Object = {}
		// holds filters params definition
		static var _args:Object = {
			BlurFilter: ["blurX","blurY","quality"],
			DropShadowFilter: ["distance","angle","color","alpha","blurX","blurY","strength","quality","inner","knockout","hideObject"],
			GlowFilter: ["color","alpha","blurX","blurY","strength","quality","inner","knockout"],
			BevelFilter: ["distance","angle","highlightColor","highlightAlpha","shadowColor","shadowAlpha","blurX","blurY","strength","quality","type","knockout"]
			
		}
		// hold saved filters states
		static var _params:Array = []
		
		// create a filter if not exist
		public static function load(type:String,params:Array):BitmapFilter {
			
  			if (!_filters[type]) {
  				var filterClass:Class = Class(getDefinitionByName("flash.filters."+type));
				_filters[type] = new filterClass()
  			}
  			
  			return _assign(type,params)
  		}
  		
  		// set filter params
  		private static function _assign(type:String,params:Array) {
  			for (var i:uint=0;i<params.length;i++) {
  				_filters[type][_args[type][i]] = params[i]
  			}
  			return _filters[type]
  		}
  		
  		// set filter params (public function)
  		public static function assign(filter:BitmapFilter,...args) {
  			return _assign(_getClassName(filter),args)
  		}
  		
  		// get filter class name
  		private static function _getClassName(filter:BitmapFilter):String {
  			var type:String = getQualifiedClassName(filter)
  			return type.substring(type.lastIndexOf(":") + 1)
  		}
  		
  		// save filter state
  		public static function push(filter:BitmapFilter) {
  			var type:String = _getClassName(filter)
  			var params:Array = []
  			
  			for (var i:uint=0;i<_args[type].length;i++) {
  				params[i] = _filters[type][_args[type][i]]
  			}
  			if (!_params[type]) _params[type] = []
  			_params[type].push(params)
  		}
  		
  		// reload saved filter state
  		public static function pop(filter:BitmapFilter) {
  			var type:String = _getClassName(filter)
  			_assign(type,_params[type].pop())
  		}
  		
  		// public methods
  		public static function DropShadowFilter(...args) 	{ return load("DropShadowFilter",args) }
  		public static function GlowFilter(...args) 			{ return load("GlowFilter",args) }
 		public static function BlurFilter(...args) 			{ return load("BlurFilter",args) }
 		public static function BevelFilter(...args) 		{ return load("BevelFilter",args) }
 		
	}
}
/* commentsOK */