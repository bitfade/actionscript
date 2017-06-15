/*
	this is an helper function used to merge xml settings to defaults value
*/
package bitfade.utils { 

	public class Misc {
			
  		public static function setDefaults(target:Object,defaults:*,justDefaults:Boolean=false,callBack:Function = null):Object {
  			if (!target) return defaults;
  			
  			var p:String;
  			
  			// if justDefaults, create a new empty object and add just defaults to it
  			if (justDefaults) {
  				var tmp:Object = {}
  				for (p in defaults) tmp[p] = target[p]
  				target = tmp
  			}
  			
  			// for each properties
  			for (p in defaults) {
  				if (target[p] === undefined) {
  					target[p] = (callBack is Function) ? callBack(defaults[p],p) : defaults[p]
				} else if (callBack is Function && defaults[p] != null) {
					// if callback, call it
					target[p] = callBack(target[p],p)
				} else if (defaults[p] is int && target[p] is String && target[p].charAt(0) == "#" ) {
					// html color
					target[p] = parseInt("0x" + target[p].substr(1))
				} else if (defaults[p] is Number || defaults[p] is uint || defaults[p] is int ) {
					// number
					target[p] = parseFloat(target[p]) 
				} else if (defaults[p] is Boolean) {
					// boolean
					target[p] = (target[p] == "true" || target[p] == true ) ? true : false 
				} else if (target[p] is Array && target[p].length == 1 && defaults[p] is Object) {
					// 1 length array, recursive call setDefaults
					target[p] = setDefaults(target[p][0],defaults[p])
				} 
			}
			// return merged object
			return target
  		}
  		
	}
}
/* commentsOK */