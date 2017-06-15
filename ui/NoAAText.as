package bitfade.ui { 
	import flash.display.*
	import flash.text.*;
	
	public class noAAText extends TextField {
		
		[Embed(source="../../common/textfields.swf#MyFontHolder")]
		private static const MyFontHolder:Class;
		
		private static var format:TextFormat;
		
		public function noAAText(txt,w,h,xp,yp) {
			
			selectable=false;
 			width = w-5;
 			height = h;
 			embedFonts = true
 			x = xp+5
 			y = yp
            
            if (!format) {
            	format = new TextFormat("Volter (Goldfish)_9pt_st",9,0xffffff,null,null,null,null,null,"left");
            }
          
          	defaultTextFormat = format;
            mouseEnabled = false
            
            htmlText = txt
            
                        /*
            var fontList:Array = Font.enumerateFonts(false);
for (var i:uint=0; i<fontList.length; i++) {
    trace("font: "+fontList[i].fontName);
}
*/
  		}
  		
	}
}