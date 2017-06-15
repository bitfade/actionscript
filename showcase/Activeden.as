/*

	Base class for intros, has common methods

*/
package bitfade.showcase {
	
	import flash.display.*
	import flash.filters.*
	import flash.events.*
	import flash.geom.*
	import flash.utils.*
	
	import bitfade.core.components.xml
	import bitfade.utils.*
	import bitfade.ui.text.*
	import bitfade.media.streams.*
	import bitfade.filters.*
	import bitfade.intros.backgrounds.*
	import bitfade.effects.*
	
	
	public class activeden extends bitfade.core.components.xml {
	
		// items
		protected var items: Array
		
		protected var back:bitfade.intros.backgrounds.background
		
		protected var container:Sprite
		
		protected var angle:Number = 0
		
		// pre boot functions
		override protected function preBoot():void {
			super.preBoot()
			
			// set defaults
			defaults.external = {
				font: "resources/fonts/Sapir.swf"
			}
			
			defaults.style = {
				text: <style><![CDATA[
					title {
						colorDark: #FFD209;
						colorLight: #466FB9;
						font-family: Sapir Sans;
						font-size: 20px;
						text-align: left;
					}
					description {
						colorDark: #FFFFFF;
						colorLight: #505050;
						font-family: Sapir Sans;
						font-size: 13px;
						text-align: left;
					}
					em {
						colorDark: #FFDF6E;
						colorLight: #466FB9;
						font-size: 13px;
						display: inline;
					}
				]]></style>.toString()
				
			}
			
			configName = "intro"
			
		}
		
		// configure the intro
		override protected function configure():Boolean {
			
			return true
			
		}
		
		// build intro layers
		override protected function build():void {
								
		}
		
		// init intro display
		override protected function display():void {
			super.display()
			background();
			loadAssets();
		}
		
		protected function loadAssets():void {
			ResLoader.load("resources/images/preview.jpg",show)
		}
		
		protected function show(el:*):void {
		
			var g = new Sprite()
		
			container = new Sprite()
			el.smoothing = true
			container.addChild(el)
			g.addChild(container)
			
			addChild(g)
			
			//root.transform.perspectiveProjection.projectionCenter = new Point(0, 0);
			//stage.transform.perspectiveProjection.focalLength = 100
			
			//var focalLength:Number = stage.transform.perspectiveProjection.focalLength
			//
			
			root.transform.perspectiveProjection.focalLength = 2000
			
			trace(stage.transform.perspectiveProjection.focalLength)
			
			container.z = 0
			
			
			Run.every(Run.FRAME,rotate)
			
			import flash.filters.*
			import bitfade.effects.*
			
			g.filters = [
				new GlowFilter(0xFFFFFF,0.2, 64,64, 2, 2)
			]
			
			var rPlane = new refPlane({target:el,width:w,height:h,alpha:100,falloff:100,autoUpdate:false})
			container.addChild(rPlane)
			rPlane.init()
			//rPlane.y = h-100
			
			rPlane.filters = [
				new BlurFilter(8,8,2)
			]
			//rPlane.y = container.y+th+conf.reflection.offset
			
			//container.transform.matrix3D.prependTranslation(-el.width/2, 0, 0)
			//container.transform.matrix3D.prependRotation(45, Vector3D.Y_AXIS);
			//container.transform.matrix3D.prependTranslation(el.width/2, 0, 0)
			
			//el.scaleX = el.scaleY = 0.5
			//container.rotationY = 50
			
			//container.x = 295
			
		}
		
		protected function rotate(): void {
			angle = 30
			container.transform.matrix3D.identity()
			//angle += 10
			//container.z = angle
			container.z = 0
			container.transform.matrix3D.appendTranslation(-295,0,0);
    		container.transform.matrix3D.appendRotation(angle++, Vector3D.Y_AXIS);
    		container.transform.matrix3D.appendTranslation(295+50,0-20,500);
			//trace(container.z)
			
			//container.transform.matrix3D.prependTranslation(0, 0, 1000)
			
			
			//container.transform.matrix3D.prependRotation(angle++, Vector3D.Y_AXIS,new Vector3D(100,0,0));
			//container.transform.matrix3D.prependTranslation(0, 0, 0)
			//container.transform.matrix3D.prependRotation(1, Vector3D.Y_AXIS);
			
		}
		
		// load intro background
		protected function background():void {
			//back = new bitfade.intros.backgrounds.intro(w,h,{color: 0x707070, color2: 0x202020 })
			//addChild(back)
			
			import bitfade.ui.backgrounds.engines.*
			
			var b = new Bitmap()
			
			Snapshot.take(bitfade.ui.backgrounds.engines.reflection.create("dark",w,h),b)
			addChild(b)
		}
	
	}
}
/* commentsOK */