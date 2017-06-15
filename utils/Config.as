/*
	this is used to get component configuration from flashVars/xml
*/
package bitfade.utils { 

	import bitfade.utils.*
	
	public class Config {
		
		public static function parse(target:*,init:Function,args:Array) {
			
			var nArgs:int = args.length
			
			var xmlConf:*
			
			if (nArgs == 1 && args[0] == false || nArgs > 3 && args[3] == false) {
				// ignore flashVars
				target.conf = target.defaults
			} else {
				// override defaults with flashVars conf
				target.conf = Misc.setDefaults(FlashVars.getConf(target.configName,true),target.defaults)
			}
			
			if (nArgs > 1) {
				// set size from parameters
				target.conf.width = args[0]
				target.conf.height = args[1]
				xmlConf = args[2] 
			} else {
				xmlConf = args[0]
			}
			
			// if no conf defined
			if (xmlConf === undefined) {
				xmlConf = target.conf.xml
			}
			
			if (xmlConf is XML) {
				init(xmlConf)				
			} else if (xmlConf is String) {
				// load external xml configuration
				ResLoader.load(xmlConf,init)
			} else {
				init()
			}
			
		}
		
		public static function getResources(conf:Object):Array {
			var extUrl:String
			var resources:Array = []
						
			for (var name:String in conf) {
				extUrl = conf[name]
				if (name == "soundFxLibrary") {
					resources.push("[soundFxLibrary]|library|"+extUrl)
				} else if (extUrl) {
					extUrl = name.match(/font/i)  ? "font|"+extUrl : extUrl
					resources.push(extUrl)
				}
			}
			
			return resources
			
		}
		
		// load external resources
		public static function loadExternalResources(conf:Object,callBack:Function):void {
			
			var resources:Array = getResources(conf)
			
			if (resources.length > 0) {
				// load external resources 
				ResLoader.load(resources,callBack)
				
			} else {
				// init display
				callBack()
			}
			
		}
 		
	}
}
/* commentsOK */