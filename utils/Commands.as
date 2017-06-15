/*
	this are function used to queue commands for later execution 
*/
package bitfade.utils { 

	import flash.utils.*
		
	public class Commands {
		
		protected static var db:Dictionary
		
		public static function queue(target:Object,command:Function,...args) {
			if (!db) db = new Dictionary(true)
			
			if (db[target]) {
				db[target].push([command,args])
			} else {
				db[target] = [[command,args]]
			}
		} 	
			
		public static function run(target:Object) {
			
			if (!db) return
			
			var list:Array = db[target]
			
			if (list) {
				for (var i:uint=0;i < list.length;i++) {
					list[i][0].apply(null,list[i][1])
				}
				delete db[target]
			}
			
		
		}
	}
}
/* commentsOK */