/*
	
	this class is used to load external content

*/
package bitfade.utils {
	
	import flash.display.*
	import flash.events.*
	import flash.net.*
	import flash.text.Font
	import flash.utils.Dictionary
	
	import flash.system.ApplicationDomain
	
	import bitfade.data.*
	import bitfade.debug
	
	public class resLoader extends EventDispatcher {
		private var resUrl:URLRequest
		
		private var queue:linkedList
		
		private var group:Dictionary;
		private var groupID:uint = 0;
		
		private var currItem:Object
		
		private var displayLoader:Loader
		private var textLoader:URLLoader
		
		private var loading:Boolean = false
		
		private var defCallBack:Function
		
		protected var delayedDestroy:*
		
		protected static var _instance:resLoader
		
		// constructor
		function resLoader(cb:* = null) {
			super()
			
			resUrl = new URLRequest()
			
			// create 2 loaders: one for images/swf, other for text
			displayLoader = new Loader();
			textLoader = new URLLoader();
			
			events.add(displayLoader.contentLoaderInfo,[Event.COMPLETE,IOErrorEvent.IO_ERROR],displayLoaderComplete,this)
			events.add(textLoader,[Event.COMPLETE,IOErrorEvent.IO_ERROR],textLoaderComplete,this)
			
			group = new Dictionary()
			queue = new linkedList()
			
			defCallBack = cb
		}
		
		public static function load(url:*,cb:* = null):uint {
			if (!_instance) _instance = new resLoader()
			return _instance.add(url,cb)
		}
		
		public static function reset(url:String,cb:Function = null):void {
			if (!_instance) return
			return _instance.kill(url,cb)
		}
		
		
		public static function openUrl(url:String,target:String):void {
			try {
  				navigateToURL(new URLRequest(url), target);
  			} catch (e:*) {}
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
		
		// this is used to remove an url from queue
		protected function kill(url:*,cb:* = null):void {
			var e:Object
			var gid:uint
			
			import bitfade.debug
			if (loading && currItem && currItem.url == url && group[currItem.groupID].callBack == cb) {
				try {
					this[currItem.type == "xml" ? "textLoader" : "displayLoader"].close()
					this[currItem.type == "xml" ? "textLoader" : "displayLoader"].unload()
					debug.log("DLT ("+currItem.groupID+") "+url)
					//loading = false
					//delete group[currItem.groupID]
					//return update()
					
					loading = false
					delete group[currItem.groupID]
					update()
				} catch (e:*) {
					debug.log("ERR ("+currItem.groupID+") "+url)
					
				}
			} else {
				var cursor:resLoaderNode
				
				while (cursor =  resLoaderNode(queue.find("url",url,cursor))) {
					if (group[cursor.groupID].callBack == cb) {
						debug.log("UNQ "+cursor.url)
						queue.deleteCurrent()
						break;
					}
				}
				
				/*
				queue.start()
				
				while(cursor = resLoaderNode(queue.next())) {
					debug.log("ITER2 "+cursor.url + " " + url)
					if (cursor.url == url && group[cursor.groupID].callBack == cb) {
						debug.log("FOUND2 "+cursor.url)
						queue.deleteCurrent()
						break;
					}	
				}
				*/
				
			}
			
			
			
		}
		
		// add a single url to queue
		private function _add(url:String):void {
			
			var token:Array = url.split(/\|/)
			
			var qi:resLoaderNode = new resLoaderNode()
			
			qi.groupID = groupID
			
			if (token[1]) {
				qi.type = "font"
				qi.url = token[1]
				// get the class name name
				qi.className = qi.url.match(/([^\/]+)\.swf$/i)[1]
				
			} else {
				qi.type = url.substring(url.lastIndexOf(".") + 1).toLowerCase()
				qi.url = url
			}
			
			queue.append(qi)
			
			update()
		}
		
		public function destroy():void {
			import bitfade.debug
			debug.log("DESTROY LOADER")
			Gc.destroy(_instance)
			_instance = undefined
			
			
		}
		
		// get a file from queue and load it
		private function update():void {
			if (loading) return 
			
			if (queue.empty) {
				currItem = undefined
				delayedDestroy=Run.after(5,destroy,delayedDestroy)
				return
			} 
			
			if (delayedDestroy) {
				Run.reset(delayedDestroy)
			}
			
			
			currItem = queue.shift()
			
			var loaderType:String = (currItem.type == "xml") ? "textLoader" : "displayLoader"
			
			resUrl.url = currItem.url
			// use appropriate loader for current item type (extension)
			this[loaderType].load(resUrl)
			loading = true
		}
		
		// this is called when a display object is loaded
		public function displayLoaderComplete(e:Event=null):void {
		
			if (!loading) return
			loading = false
			
			//if (!group[currItem.groupID]) return
			
			var content:Object = group[currItem.groupID].content
			
			if (e && e.type == IOErrorEvent.IO_ERROR) {
				content.push(undefined)
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
					content.push(className)
				} else {
					content.push(displayLoader.content) 
				}
			
				
			}
			
			displayLoader.unload()
			callCallBack(currItem)
		}
		
		// this is called when a text object is loaded
		public function textLoaderComplete(e:Event=null):void {
			loading = false
			
			var content:Object = group[currItem.groupID].content
			
			if (e && e.type == IOErrorEvent.IO_ERROR) {
				content.push(undefined)
			} else {
				content.push((currItem.type == "xml") ? new XML(textLoader.data) : textLoader.data)
			}
			
			callCallBack(currItem)
		}
		
		// call callback, if defined, and delete info
		private function callCallBack(item:*):void {
		
			var g:Object = group[item.groupID]
			
			g.loaded++
			if (g.loaded == g.total) {
				if (g.callBack) {
					g.callBack((g.total == 1) ? g.content[0] : g.content)
				}
				delete group[item.groupID]
			}
			g = undefined
			currItem = undefined
			update()
		}

	}
}

internal class resLoaderNode extends bitfade.data.llNode {
	public var type:String
	public var url:String
	public var groupID:uint
	public var className:String
}
