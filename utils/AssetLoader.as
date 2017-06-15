/*
	used to load assets in progressive way
*/
package bitfade.utils { 

	import flash.display.*
	import flash.events.*
	import flash.utils.*
	
	import bitfade.core.*
	import bitfade.data.*
	import bitfade.utils.*
	
	public class AssetLoader extends EventDispatcher {
	
		protected var loadQueue:LinkedList
		protected var assets:Array
		protected var current: ContentNode
		protected var loaded:uint = 0
		protected var cached:Dictionary;
		protected var rlID:uint = 0;
		
		public var loading:Boolean = false
		
		public var readyCallBack:Function
		public var transformCallBack:Function
		
		public var cacheSize:uint = 2
		public var resources:uint = 0
		
		protected var _randomAccess:Boolean = false;
		protected var customDB:Array
		protected var delayedDB:Dictionary
		
		
		public function AssetLoader(items:Array,callBack:Function,trasform:Function = null) {
			assets = items
			readyCallBack = callBack
			transformCallBack = trasform
		}
		
		public function set random(r:Boolean) {
			_randomAccess = r
			if (r) {
				cacheSize = 2
			}
		}
		
		public function start() {
			if (!assets) return
			
			// get the list of external assets
			for each (var asset:Object in assets) {
				if (asset.resource && asset.resource != "") {
				
					// create the queue					
					if (!loadQueue) loadQueue = new LinkedList()
			
					current = new ContentNode()
					
					current.content = {
						resource: 	asset.resource
						
					}
					
					if (_randomAccess || asset.resource is Array) {
					
						current.content.target = asset
					}
					
					// add the node
					loadQueue.append(current)
					asset.resource = current
					resources++
				}
				
			}
			
			if (loadQueue) {
				// resize the cache
				cacheSize = Math.min(cacheSize,loadQueue.length)
				cached = new Dictionary(false);
				
				loadQueue.rewind()
				loadAsset()
				
				Events.add(ResLoader.instance,[ResLoaderEvent.PROGRESS],progressHandler,this)
				
			} else {
				readyCallBack()
			}
		}
		
		protected function progressHandler(e:ResLoaderEvent) {
			if (e.gid == rlID && willTrigger(ResLoaderEvent.PROGRESS)) dispatchEvent(e)
		}
		
		protected function loadAsset() {
			
			if (loaded >= cacheSize) {
				// cache is full
				//printList("CALL "+current.content.target.id)
				readyCallBack()
				return
			} 
			
			
			// load the asset
			current = ContentNode(loadQueue.next)
			if (!current) {
				loadQueue.rewind()
				current = ContentNode(loadQueue.next)
			}
			
			//if (cached[current]) return
			loading = true
			//printList("LOAD "+current.content.target.id)
			
			rlID = ResLoader.load(current.content.resource,assetLoaded)
						
		}
		
		// current asset is loaded
		protected function assetLoaded(data:*) {
		
			loading = false;
			loaded++
			
			//printList("OK   "+current.content.target.id)
			
			if (current.content.target) {
				current.content.data = (transformCallBack != null) ? transformCallBack(data,current.content.target) : data
			} else {
				current.content.data = (transformCallBack != null) ? transformCallBack(data) : data
			}
			
			cached[current] = true
			
			loadAsset()
		}
		
		// get data (external asset) for a given item
		public function getData(item:Object):* {
			//printList("FC  "+item.id)
			if (!item || !item.resource || !item.resource.content || !item.resource.content.data) return null
			
			var data:* = item.resource.content.data
			if (loadQueue.length > cacheSize) {
				clearCache(item.resource);
				next()
			}
			return data
		}
		
		protected function clearCache(item:ContentNode) {
			delete cached[item];
			delete item.content.data
				
		}
		
		// ready if asset is loaded (or asset is not external)
		public function ready(item:Object):Boolean {
			//printList("GET  "+item.id)
			
			if (item && item.resource == "") return true
			if (!item || !item.resource ) return false	
			var cached:Boolean = item.resource.content.data
			
			
			if (delayedDB && delayedDB[item]) {
				delete delayedDB[item]
				cached = false
			}
			
			if (_randomAccess && !cached) {
				if (loading) {
					ResLoader.reset(current.content.resource,assetLoaded)
					loading = false
					loaded = cacheSize
				}
				findNode(item)
				next()
			}
			
			return cached;
		}
		
		public function getCustomUrl(url:String,callBack:Function,conf:Object = null):String {
			var customID:uint = ResLoader.getNextCustomID
			if (!customDB) {
				customDB = new Array()
				Events.add(ResLoader.instance,[ResLoaderEvent.CUSTOM_LOAD,ResLoaderEvent.CUSTOM_ABORT],customEventHandler,this)
			}
			
			customDB[customID] = {handler:callBack, url:url}
			if (conf) customDB[customID].conf = conf
			
			return customID+".custom";
		}
		
		public function getResourceFromID(id:uint):* {
			if (customDB[id]) return customDB[id].url
			return undefined
		}
		
		public function getConfFromID(id:uint):* {
			if (customDB[id]) return customDB[id].conf
			return undefined
		}
		
		protected function customEventHandler(e:ResLoaderEvent) {
			var el:Object = customDB[e.gid]
			if (el) {
				if (e.type == ResLoaderEvent.CUSTOM_LOAD) {
					el.handler(e.gid)
				} else {
					dispatchEvent(e)
				}
					
			}			
		}
		
		public function customLoaderProgress(id:uint,ratio:Number) {
			ResLoader.instance.customLoaderProgress(ratio)
		}
		
		public function customLoaderComplete(id:uint,data:*):void {
			if (data === false) {
				var target:* = current.content.target
				if (!delayedDB) delayedDB = new Dictionary(false)
				delayedDB[target] = true
			}
			ResLoader.instance.customLoaderComplete(data)
		}
		
		
		/*
		protected function printList(id:String) {
			var node:*= loadQueue.head
			var buffer:String=""+id+" ("+loaded+") -> "
			var id:String;
			var code:String;
			
			while (node = node.next) {
				id = node.content.target.id 
			
				code = (node.content.data) ? "[" + id +"]": id
			
				if (node == current) code = "C"+code
				
				buffer += code
				buffer += " "
			}
			trace(buffer)
			
		}
		*/
		
		public function findNode(item:Object) {
			var node:ContentNode
			
			loadQueue.rewind()
						
			while (node = loadQueue.next) {
				//node.content.data = Gc.destroy(node.content.data,true)
				if (node.next && ContentNode(node.next).content) {
					if (ContentNode(node.next).content.target == item) break;
				}
				//prev = node
			}
			
			// clear cache
			for (var ci in cached) {
				clearCache(ci)
			}
			
			
		}
		
		// load next asset
		public function next() {
			loaded--
			if (!loading) loadAsset()
		}
		
		public function get fullCached():Boolean {
			return resources <= cacheSize
		} 
		
		protected function nodeDestroyer(node:ContentNode) {
			node.content.target = undefined
			
			if (node.content.data) {
				node.content.data = Gc.destroy(node.content.data,true)
			}
			
		}
		
		public function destroy() {
			loadQueue.destroy(nodeDestroyer)
			if (customDB) {
				for (var idx:String in customDB) {
					customDB[idx].handler = undefined
					delete customDB[idx]
				}
			}
			
			if (delayedDB) {
				for (var item:* in delayedDB) {
					delete delayedDB[item]
				}
			}
			
			Gc.destroy(this)
		}
				
	}
}
/* commentsOK */