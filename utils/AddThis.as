/*
	addThis interface functions
*/
package bitfade.utils { 

	public class AddThis {
	
		import flash.net.*
		import bitfade.utils.Boot
	
		public static const ENDPOINT:String = "http://api.addthis.com/oexchange/0.8/forward";
		public static const fields:Array = ["username","url","swfurl","width","height","title","description","screenshot"];
				
		public static function share(options:Object):void  {
			
			var network:String = options.type
			
			if (network == "more") network = "" 
			
			var params:URLVariables = new URLVariables();
            
            if (options.swfurl && Boot.stage) {
				if (!options.width) options.width = Boot.stage.stageWidth
				if (!options.height) options.height = Boot.stage.stageHeight
			}
            
            for each (var prop:String in fields) {
            	if (options[prop]) {
            		params[prop] = options[prop]
            	}
            }
           
            network &&= "/"+network
            
            var request:URLRequest = new URLRequest(ENDPOINT + network  + '/offer');
            request.data = params;
            
            try {
            	navigateToURL(request, '_blank'); 
            } catch (e:*) {}
		} 		
	}
}
/* commentsOK */