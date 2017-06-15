package bitfade {

	// tb class
	import org.osflash.thunderbolt.Logger

	public class Debug {
	
		public static var buffer:String = ""
	
		public static function log(title,value=null) {
			var t = title is String ? title : title.toString()
			if (value != null) {
				Logger.info(t,value)
			} else {
				Logger.info(t)
			}
		}
		
		public static function add(...args) {
			var msg:String = args.join(",")
			if (msg != "") buffer += (buffer != "" ? "," : "") + args.join(",")
		}
		
		public static function print(...args) {
			add.apply(null,args)
			trace(buffer)
			buffer=""
		}
	
	}
}
