/*

	external background image

*/
package bitfade.intros.backgrounds {
	
	import flash.display.*
	import bitfade.utils.*
	
	public class Image extends Background {
	
		protected var onReadyCallBack:Function
		
		public function Image(...args) {
			configure.apply(null,args)
		}
		
		override protected function init():void {
			super.init()
			
			ResLoader.load(conf.resource,assetLoaded)			
		}
		
		override public function onReady(cb:Function) {
			onReadyCallBack = cb
		}
		
		protected function assetLoaded(content):void {
			if (content) {
				var scaler:Object = Geom.getScaler("fillmax","center","center",w,h,content.width,content.height)
					
				// get a target snapshot
				addChild(new Bitmap(Snapshot.take(content,null,w,h,Geom.getScaleMatrix(scaler))))
			}
			
			if (onReadyCallBack != null) onReadyCallBack()
			
			
		}
		
	}

}
/* commentsOK */