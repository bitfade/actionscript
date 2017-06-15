package gl.effects.reflect{ 
	
	import flash.geom.*
	import flash.display.*
	
	public class refObject {
		private var mc:MovieClip;
		private var bMap:Bitmap;
		private var bData:BitmapData;
		private var conf:Object = {};
		
		private static var refM:Matrix;
		private static var alphaC:BitmapData;
		private static var origin:Point;
		private static var box:Rectangle;
		private static var falloff:Number;
		
		function refObject(mc,args:Object=null){
			this.mc = mc;
			
			if (!refM) {
				falloff = (args && args.falloff) ? args.falloff : 80
				
				refM = new Matrix()
				
				var wMax = 1280
				
				origin = new Point(0,0);
				box = new Rectangle(0,0,wMax,1);
				
				alphaC = new BitmapData(wMax, falloff, true,0x000000);
				
				for (var i=0,alpha=0,delta=(200/falloff)<<24; i<=falloff; i++,alpha+=delta) {
					box.y = i
					alphaC.fillRect(box,alpha)
				}
				with (box) { 
					y=0;
					height = falloff;
				}
				
			} 
					
			//with (mc.scrollRect ? mc.scrollRect : mc ) {
			with (mc) {
					conf.x = x;
					conf.y = y;
					conf.w = width;
					conf.h = height;
			}
			
			bData = new BitmapData(conf.w, falloff, true,0x000000);			
			bMap = new Bitmap(bData);
			
			bMap.scaleY = -1;
			bMap.y = conf.h+falloff;
			add()
			
		}
		
		public function update() {
			bData.draw(mc,refM,null,null,box);
			bData.copyChannel(alphaC,box,origin,BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA)
		}
		
		public function add() {
			box.width = conf.w
			refM.ty = -(conf.h-falloff);
			update();
			
			mc.addChild(bMap)
			
		}
		
	}
}