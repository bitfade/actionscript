/*
	
	this class is used to load external fonts
	
	put content in 
	
	bitfade/utils/externalFontLoader.as

	Example usage
		
	import bitfade.utils.*
	
	externalFontLoader.load("resources/fonts/Silkscreen.swf",fontLoaded)
			
			
	function fontLoaded(loaded:Boolean) {
		// loaded == true -> font is loaded
		
		trace(loaded)
  			
  		// display all loaded fonts
  		
  		import flash.text.*
  		var fontList:Array = Font.enumerateFonts(false)
  			
  		for (var i:uint=0; i<fontList.length; i++) 
  				trace(fontList[i].fontName)
		}
  			
  	}
  		


*/
package bitfade.utils {
	
	import flash.display.*
	import flash.events.*
	import flash.net.*
	import flash.text.Font
	
	import flash.system.ApplicationDomain
	
	
	public class externalFontLoader extends EventDispatcher {
		
		protected var resUrl:URLRequest
		protected var displayLoader:Loader
		protected var callBack:Function
		
		protected static var _instance:externalFontLoader
		
		protected var listenTo:Array = [Event.COMPLETE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR]
		
		
		// constructor
		function externalFontLoader() {
			super()
			
			resUrl = new URLRequest()
			displayLoader = new Loader();
			
			for each (var ev:String in listenTo) {
				displayLoader.contentLoaderInfo.addEventListener(ev,displayLoaderComplete)
			}
		}
		
		public static function load(url:*,cb:Function):void {
			if (_instance == null) _instance = new externalFontLoader()
			_instance.add(url,cb)
		}
		
		// this is used to add an url (or more) to queue
		protected function add(url:String,cb:Function):void {
			callBack = cb
			resUrl.url = url
			displayLoader.load(resUrl)	
		}
		
		
		public function destroy():void {
			for each (var ev:String in listenTo) {
				displayLoader.contentLoaderInfo.removeEventListener(ev,displayLoaderComplete)
			}
			
			_instance = undefined
		}
		
		// this is called when a display object is loaded
		public function displayLoaderComplete(e:Event=null):void {
		
			if ((e && (e.type == IOErrorEvent.IO_ERROR || e.type == SecurityErrorEvent.SECURITY_ERROR)) || !displayLoader.contentLoaderInfo.childAllowsParent) {
				callBack(false)
			} else {
				var type:String = "font"
				var className:String = resUrl.url.match(/([^\/]+)\.swf$/i)[1]
				
				var ad:ApplicationDomain = e.target.applicationDomain
				// register font (or fonts)
				var fonts:* = ad.hasDefinition(type) ? ad.getDefinition(type) : ad.hasDefinition(className) ? ad.getDefinition(className)[type] : false
				if (fonts) {
					if (!(fonts is Array)) fonts = [fonts]
					for each (var font:Class in fonts) {
						Font.registerFont(font)
					}
				}
				displayLoader.unload()
				callBack(true)						
			}
			
		}
		

	}
}

