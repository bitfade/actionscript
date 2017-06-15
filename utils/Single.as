/*
	singletons helper class
*/
package bitfade.utils { 

	import bitfade.utils.*
	import flash.utils.*

	public final class Single {
		
		public static var registry:Dictionary
		public static var delayed:Dictionary
		
		// create (or request) a single instance of a class
 		public static function instance(id:String,c:Class):* {
 			if (!registry) {
 				registry = new Dictionary()
 			}
 			if (!registry[id]) {
 				// no instances found, create
 				registry[id] = new c()
 			}
 			// reset any destroyer set to this 
 			resetDelayedDestroy(id)
 			
 			return registry[id]
 		}
 		
 		// destroy a singleton after timeout seconds
 		public static function remove(id:String,timeout:Number = 15):void {
 			if (!id || !registry || !registry[id]) return
 			
 			if (!delayed) {
 				delayed = new Dictionary()
 			}
 			
 			if (!delayed[id]) {
 				delayed[id] = Run.after(timeout,clean,undefined,false,0,0,true,id)
 			}
 			
 		}
 		
 		// reset destroyer
 		protected static function resetDelayedDestroy(id:String) {
 			if (delayed && delayed[id]) {
 				Run.reset(delayed[id])
 				delete delayed[id]
 				if (delayed.length == 0) delayed = undefined
 			}
 		}
 		
 		// do the actual removing of singleton
 		protected static function clean(ratio:Number,id:String) {
 			resetDelayedDestroy(id)
 			if (registry[id]) {
 				Gc.destroy(registry[id])
 				delete registry[id]
 			}
 			if (registry.length == 0) registry = undefined
 		}
 		
	}
}
/* commentsOK */
