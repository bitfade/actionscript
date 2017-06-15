/*
	
	this class is used to load external content

*/
package bitfade.utils {
	
	import flash.display.*
	import flash.events.*
	import flash.net.*
	import flash.system.*
	import flash.text.Font
	import flash.utils.Dictionary
	
	import flash.system.ApplicationDomain
	
	import bitfade.data.*
	
	public class ResLoader extends EventDispatcher {
		private var resUrl:URLRequest
		
		private var queue:LinkedListPool
		
		private var group:Dictionary;
		private var groupID:uint = 0;
		
		private var currItem:ResLoaderNode
		
		private var displayLoader:Loader
		private var textLoader:URLLoader
		private var loaderContext:LoaderContext
		
		private var loading:Boolean = false
		
		private var defCallBack:Function
		
		private static var basePath: String
		private var domain: String
		
		protected var delayedDestroy:*
		protected var singleEvent:ResLoaderEvent;
		
		protected static var customID:uint = 0
		protected static var _instance:ResLoader
		
		protected var displayLoaderFix:RunNode
		
		// constructor
		function ResLoader(cb:* = null) {
			super()
			
			loaderContext = new LoaderContext();
			loaderContext.checkPolicyFile = true;
			
			if (!basePath) setBasePath("swf")
			
			//loaderContext.applicationDomain = ApplicationDomain.currentDomain;
			
			resUrl = new URLRequest()
			
			// create 2 loaders: one for images/swf, other for text
			createDisplayLoader()
			textLoader = new URLLoader();
			
			Events.add(textLoader,[Event.COMPLETE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR],textLoaderComplete,this)
			Events.add(textLoader,[ProgressEvent.PROGRESS],progressHandler,this)
			
			group = new Dictionary()
			queue = new LinkedListPool(ResLoaderNode,"type","url","groupID","className","id")
			
			currItem = new ResLoaderNode()
			defCallBack = cb
		}
		
		protected function createDisplayLoader() {
			if (displayLoader) {
				try { displayLoader.unload() } catch (e:*) {}
				Events.remove(displayLoader.contentLoaderInfo)
			}
			
			displayLoader = new Loader();
			Events.add(displayLoader.contentLoaderInfo,[Event.COMPLETE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR],displayLoaderComplete,this)
			Events.add(displayLoader.contentLoaderInfo,[ProgressEvent.PROGRESS],progressHandler,this)
			
		}
		
		// load an asset
		public static function get instance():ResLoader {
			if (_instance == null) _instance = new ResLoader()
			return _instance
		}
		
		// load an asset
		public static function load(url:*,cb:* = null):uint {
			if (_instance == null) _instance = new ResLoader()
			return _instance.add(url,cb)
		}
		
		public static function get getNextCustomID() {
			return ++customID
		}
		
		// load an asset
		public static function strip(url:String):uint {
			if (_instance == null) _instance = new ResLoader()
			return _instance._strip(url)
		}
		
		// set base path
		public static function set base(url:String) {
			if (_instance == null) _instance = new ResLoader()
			return _instance.setBasePath(url)
		}
		
		// reset a download
		public static function reset(url:*,cb:Function = null):void {
			if (_instance == null) return
			return _instance.kill(url,cb)
		}
		
		// static method for opening an external url
		public static function openUrl(url:String,target:String = "_self"):void {
			try {
  				navigateToURL(new URLRequest(url), target);
  			} catch (e:*) {}
		}
		
		// set the base path for relative urls
		protected function setBasePath(url:String = null) {
			if (url) {
				switch (url) {
					case "swf":
						basePath = Boot.stage.loaderInfo.url.replace(/[^(\/|\\)]+\.swf(\?.+)?$/,"")
					break;
					default:
						basePath = url
				}
				//domain = boot.stage.loaderInfo.url.split("/").slice(0,3).join("/")	
			}
		}
		
		protected function _strip(url:String) {
			return url.replace(basePath,"")
		}
		
		// this is used to add an url (or more) to queue
		protected function add(url:*,cb:* = null):uint {
			
			
			if (cb == null) cb = defCallBack
		
			if (url is String) url = [url]
			
			group[groupID] = {
				urls: url,
				total: url.length,
				loaded: 0,
				callBack: cb,
				content: []
			}
			
			for each (var u:String in url) _add(u) 
			
			return groupID++
		}
		
		protected function stripID(url:String):String {
			var token:Array = url.split(/\|/)
			
			if (token[1] && token[0].charAt(0) == "[") {
				return  token[1]
			}
			
			return url
		}
		
		// add a single url to queue
		private function _add(url:String):void {
			
			var token:Array = url.split(/\|/)
			
			var qi:ResLoaderNode = queue.create()
			
			qi.groupID = groupID
			
			if (token[1] && token[0].charAt(0) == "[") {
				qi.id = token[0]
				qi.id = qi.id.substring(1,qi.id.length-1);
				url = token[1]
				// check this
				token.shift()
				// instead of this
				//delete token[1]
			} else {
				qi.id = undefined
			}
			
			if (token[1]) {
				qi.type = token[0] == "font" ? "font" : "library"
				
				qi.url = absoluteUrl(token[1])
				// get the class name name
				qi.className = qi.url.match(/([^\/]+)\.swf$/i)[1]
				
			} else {
				qi.type = url.substring(url.lastIndexOf(".") + 1).toLowerCase()
				qi.url = qi.type == "custom" ? url.replace(/.custom$/,"") : absoluteUrl(url)
			}
			
			queue.append(qi)
			
			update()
		}
		
		// make url absolute
		public static function absoluteUrl(url:String):String {
			if (!basePath || url.charAt(0) == "/" || url.indexOf("http://") == 0 || url.indexOf("https://") == 0  ) return url
			return basePath+url
		}
		
		// this is used to remove an url from queue
		protected function kill(u:*,cb:* = null):void {
		
			var urls:Array = u is Array ? u : [u]; 
			
			var e:Object
			var gid:uint
			
			var callUpdate:Boolean = false;
			
			for each (var url:String in urls) {
							
				url = currItem.type == "custom" ? stripID(url).replace(/.custom$/,"") : absoluteUrl(stripID(url))
				
				if (loading && currItem && currItem.url == url && group[currItem.groupID] && group[currItem.groupID].callBack == cb) {
					delete group[currItem.groupID]
					callUpdate = true
					try {
						if (currItem.type == "custom") {
							dispatchEvent(new ResLoaderEvent(ResLoaderEvent.CUSTOM_ABORT,parseInt(currItem.url)))
						} else if (currItem.type == "xml") {
							textLoader.close()
						} else {
							if (displayLoaderFix) displayLoaderFix = Run.reset(displayLoaderFix)							
							displayLoader.close()
							displayLoader.unload()
						}
					} catch (e:*) {}
				} else {
					
					queue.rewind()
					
					var cursor:ResLoaderNode
					while(cursor = queue.next) {
						if (!group[cursor.groupID] || (cursor.url == url && group[cursor.groupID].callBack == cb)) {
							queue.deleteCurrent()
							break
						}	
					}
					
				}
				
			}
			
			if (callUpdate) {
				loading = false
				update()
				//Run.after(1,update)
			}

			
		}
		
		// destroy the instance
		public function destroy():void {
			if (willTrigger(ResLoaderEvent.CUSTOM_LOAD)) {
				delayedDestroy=Run.after(60,destroy,delayedDestroy)
				return
			}
			Gc.destroy(_instance)
			queue.destroy()
			_instance = undefined
			
			
		}
		
		// get a file from queue and load it
		private function update():void {
		
			if (loading) return 
			
			if (queue.empty) {
				delayedDestroy=Run.after(60,destroy,delayedDestroy)
				return
			} 
			
			if (delayedDestroy) {
				Run.reset(delayedDestroy)
			}
			
			queue.shift(currItem)
			loadLoader()
		}
		
		private function loadLoader():void {
			resUrl.url = currItem.url
			
			
			// use appropriate loader for current item type (extension)
			if (currItem.type == "custom") {
				loading = true
				dispatchEvent(new ResLoaderEvent(ResLoaderEvent.CUSTOM_LOAD,parseInt(currItem.url)))
				return
			
			} else if (currItem.type == "xml") {
				textLoader.load(resUrl)
			} else {
				// disable policy checking for external font packages
				// dunno why but it breaks Font register randomly
				displayLoader.load(resUrl,currItem.type != "font" ? loaderContext : null)
			}
			
			loading = true
		}
		
		protected function pushContent(data:*) {
		
			var id:String = currItem.id
			
			var iGroup:Object = group[currItem.groupID]
			var idx:* 
		
			//trace("PUSH",currItem.groupID,id,displayLoader.content.loaderInfo.url)
		
			if (id) {
				if (iGroup.content is Array) {
					iGroup.content = {}
				} 
				
				idx = id.match(/([0-9]+)$/i)
				if (idx != null) {
					idx = idx[0]
					id = id.substring(0,id.length-idx.length)
					if (!iGroup.content[id]) iGroup.content[id] = {}
					iGroup.content[id][idx] = data
				} else {
					iGroup.content[id] = data
				}
				
			} else {
				iGroup.content.push(data)
			}
			
		}
		
		public function customLoaderComplete(data:*):void {
			loading = false
			if (group[currItem.groupID]) {
				customLoaderProgress(1)
				var content:Object = group[currItem.groupID].content
				pushContent(data)
				callCallBack(currItem.groupID)
			}
		}
		
		protected function fixDisplayLoader() {
			displayLoaderComplete(new Event("complete"))
		}
		
		// this is called when a display object is loaded
		public function displayLoaderComplete(e:Event=null):void {
			
			//trace("LOADED",displayLoader.content.loaderInfo.url)
			
			if (e.type == "complete" && !displayLoader.content) {
				if (!displayLoaderFix) {
					displayLoaderFix = Run.after(0.1,fixDisplayLoader)
				}
				return
			} 
			
			if (displayLoader.content && displayLoader.content.loaderInfo && displayLoader.content.loaderInfo.url != currItem.url) {
				createDisplayLoader()				
				loadLoader()
				return
			}
			
			loading = false
			if (displayLoaderFix) displayLoaderFix = Run.reset(displayLoaderFix)
			
			if (group[currItem.groupID]) {
				
				//if (!group[currItem.groupID]) return
				var content:Object = group[currItem.groupID].content
				
				if ((e && (e.type == IOErrorEvent.IO_ERROR || e.type == SecurityErrorEvent.SECURITY_ERROR)) || !displayLoader.contentLoaderInfo.childAllowsParent) {
					pushContent(undefined)
				} else {
					var type:String = currItem.type
					var className:String = currItem.className
					
					if (type == "font") {
						var ad:ApplicationDomain = e.target.applicationDomain
						// register font (or fonts)
						var fonts:* = ad.hasDefinition(type) ? ad.getDefinition(type) : ad.hasDefinition(className) ? ad.getDefinition(className)[type] : false
						if (fonts) {
							if (!(fonts is Array)) fonts = [fonts]
							for each (var font:Class in fonts) {
								Font.registerFont(font)
							}
						}
						if (content is Array) content.push(className)
					} else if (type=="library") {
						pushContent(e.target.applicationDomain) 
					} else {
						pushContent(displayLoader.content)
					}
				}
				displayLoader.unload()
				callCallBack(currItem.groupID)
				
			} else {
				displayLoader.unload()
			}
		}
		
		// this is called when a text object is loaded
		public function textLoaderComplete(e:Event=null):void {
			loading = false
			
			var content:Object = group[currItem.groupID].content
			
			if (e && (e.type == IOErrorEvent.IO_ERROR || e.type == SecurityErrorEvent.SECURITY_ERROR)) {
				content.push(undefined)
			} else {
				content.push((currItem.type == "xml") ? new XML(textLoader.data) : textLoader.data)
			}
			
			callCallBack(currItem.groupID)
		}
		
		public function customLoaderProgress(ratio:Number) {
			progressHandler(null,ratio)
		}
		
		protected function progressHandler(e:ProgressEvent = null,r:Number = 0) {
		
			if (!willTrigger(ResLoaderEvent.PROGRESS)) return
		
			var gID:uint = currItem.groupID
			
			if (!group[gID]) return
			
			var ratio:uint = e ? Math.round(100*e.bytesLoaded/e.target.bytesTotal) : Math.round(r*100)
			var loaded:uint = group[gID].loaded
			if (ratio >= 100) loaded++ 
			
			if (!singleEvent) {
				singleEvent = new ResLoaderEvent(ResLoaderEvent.PROGRESS)
			}
			
			singleEvent.gid = gID
			singleEvent.ratio = ratio
			singleEvent.total = group[gID].total
			singleEvent.loaded = loaded
			
			dispatchEvent(singleEvent)
			
		}
		
		// call callback, if defined, and delete info
		private function callCallBack(gid:uint):void {
		
			var gData:Object = group[gid]
			
			gData.loaded++
			if (gData.loaded == gData.total) {
				if (gData.callBack) {
					gData.callBack((gData.total == 1 && gData.content is Array) ? gData.content[0] : gData.content)
				}
				delete group[gid]
			}
			update()
		}

	}
}

internal class ResLoaderNode extends bitfade.data.LLNode {
	public var id:String
	public var type:String
	public var url:String
	public var groupID:uint
	public var className:String
}
/* commentsOK */
