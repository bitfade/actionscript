/*

	Base class for custom bitmapData filters

*/
package bitfade.filters {
	
	import flash.display.*
	
	import bitfade.utils.*
	import bitfade.easing.*
	import flash.utils.*
	
	public class Filter {
	
		// apply a filter chain to a display object
		public static function apply(target:*,filters:*,crop:Boolean = false):Bitmap {
			
			if (!filters && !crop) return target;
			
			var fc:Class
			var fcName:String
			var tokens:Array
			var bData:BitmapData
			var bMap:Bitmap
			
			if (filters is String) {
				filters = filters.split(",")
			}
			
			for each (var name:String in filters) {
				tokens = name.split(/:/)
				name = tokens[0]
				tokens[0] = target
				fcName = "bitfade.filters." + name.charAt(0).toUpperCase() + name.substring(1,name.length).toLowerCase();
				try {
					fc = Class(getDefinitionByName(fcName));
					
					if (!bMap) {
						bMap = new Bitmap()
					}
					bData = fc["apply"].apply(null,tokens)
					bMap.bitmapData = bData
					
					target = bMap
				} catch (e:*) {}
			}
			
			return target
		}
			

	}
}
/* commentsOK */