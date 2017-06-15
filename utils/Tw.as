/*
	this are wrapper function used to call tween engine
*/
package bitfade.utils { 

	import com.gskinner.motion.*
	import com.gskinner.motion.plugins.*

	import flash.utils.Dictionary

	public class Tw extends GTween {
		
		myInit()
		
		public static function myInit() {
			// install Snapping Plugin
			com.gskinner.motion.plugins.SnappingPlugin.install()
		}
		
		public function Tw(target:Object=null, duration:Number=1, values:Object=null, props:Object=null, pluginData:Object=null) {
			super(target, duration, values, props, pluginData)
		}
		
		public static function to(target:Object=null, duration:Number=1, values:Object=null, props:Object=null, pluginData:Object=null):Tw {
			return new Tw(target, duration, values, props, pluginData);
		}
		
		public static function unique(db:Dictionary,target:Object=null, duration:Number=1, values:Object=null, props:Object=null, pluginData:Object=null):Tw {
			
			var tween:Tw = db[target]
			
			if (tween) {
				for (var p:String in values) {
					tween.setValue(p,values[p])
				}
			} else {
				tween = db[target] = new bitfade.utils.Tw(target, duration, values, props, pluginData);
			}
			
			return tween
		}
 		
	}
}
/* commentsOK */