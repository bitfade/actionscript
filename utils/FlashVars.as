/*
	this are helper functions used to parse and get flashVars 
*/
package bitfade.utils { 

	import bitfade.utils.Boot
	
	public class FlashVars {
	
		private static var parsed:Object
		
		// parse flashVars
		private static function parse():void {
		
			var fv:Object = Boot.stage.loaderInfo.parameters
			var tokens:Array
			var i:uint = 0;
			var parent:Object
			
			parsed = {}
			
			// group flashvars using "." separed tokens
			for (var p:String in fv) {
				tokens = p.split(/\./)
				if (tokens.length > 1) {
					parent = parsed
					for (i = 0; i< tokens.length-1;i++) {
						if (!parent[tokens[i]]) parent[tokens[i]] = {}
						parent = parent[tokens[i]]
					}
					parent[tokens[i]] = fv[p]
				} else {
					parsed[p] = fv[p]
				}
			}
		}
		
		// get flashVars
		public static function getConf(key:String,xmlMergeCompatible:Boolean = false):* {
		
			if (!parsed) parse()
			if (!parsed[key]) return {}
			
			if (!xmlMergeCompatible) return parsed[key]
			
			// return the object in same form as parsed xml
			var fvConf:Object = parsed[key]
			var conf:Object = {}
			
			for (var p:String in fvConf) {
				 conf[p] = (fvConf[p] is String) ? fvConf[p] : [fvConf[p]]
			}
			
			return conf
			
		}
 		
	}
}
/* commentsOK */