/*
	this are helper functions used to clean stuff
*/
package bitfade.utils { 

	import flash.display.*
	import flash.utils.getQualifiedClassName

	import bitfade.core.*
	import bitfade.utils.*
	
	public class Gc {
	
		public static function destroy(target:*,objectMode:Boolean = false,destroyTarget:Boolean = true):* {
		
			if (destroyTarget) {
			
				Events.remove(target)
				FastTw.remove(target)
				
				if (target is DisplayObject && target.parent) target.parent.removeChild(target)
				
				if (target is Bitmap && target.bitmapData) {
					target.bitmapData.dispose()
					target.bitmapData = undefined
					return undefined
				} 
			
			}
			
			if (target is DisplayObjectContainer) {
				var child:*
				
				while(target.numChildren) {
					try {
						child = target.getChildAt(0);
					} catch (e:*) {
						break;
					}
					
					if (child is bitfade.core.IDestroyable) {
						child.destroy()
					} else {
						destroy(child)
					}
					
					child = undefined
				}
			
			} else if (objectMode && (target is Array || target is Object)) {
				for (var p in target) Gc.destroy(target[p],true)
			}
			

			
			target = undefined
			return undefined
						
		}
		
		public static function destroyChildrens(target:DisplayObjectContainer) {
			destroy(target,false,false)
		} 
				
	}
}
/* commentsOK */