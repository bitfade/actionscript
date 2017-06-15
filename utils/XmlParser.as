/*

	this class will convert a XML configuration in to a simpler object 

*/
package bitfade.utils { 

	import flash.xml.*

	public class XmlParser {
		public static function toObject(xml:XML):Object {
		
			var obj:Object = {}
			var el:XML
			var name:String
			var value:Object
	
			// for each attribute
			for each(el in xml.@*) {
				name = el.localName()
				obj[name] = String(xml.attribute(name));
			}
			
			// if have text, add it 
			value = xml.text().toString()
			if (value) obj.content = value
	
			// for each element	
			if (xml.hasComplexContent()) { 
				for each(el in xml.*) {
					name = el.localName()
					value = XmlParser.toObject(el)
					if (obj[name] is Array) {
						obj[name].push(value)
					} else {
						obj[name] = [value]
					}
				}
			}
	
			return obj
		
		}
		
		// strips namespaces for simpler parsing
		public static function clean(input:XML):XML {
			var purified:String = input.toString()
			purified = purified.replace(/<(\/)?(\w+:)(\w+)/g, "<$1$3");
			purified = purified.replace(/\w+:(\w+)=\"/g, "$1=\"");
			purified = purified.replace(/xmlns(:\w+)?=\"([^\"]+)\"/g, "");
			return new XML(purified)
		}
	}
}
/* commentsOK */