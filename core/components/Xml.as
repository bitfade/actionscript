/*

	Base class for xml based widgets

*/
package bitfade.core.components {
	
	import flash.display.*
	import flash.text.*
	import bitfade.core.*
	import bitfade.utils.*
	import bitfade.ui.spinners.*
	import bitfade.ui.text.TextField
	
	public class Xml extends Sprite implements bitfade.core.IBootable,bitfade.core.IResizable,bitfade.core.IDestroyable {
	
		public var configName:String = "component"
	
		/*
			config defaults, NO EDIT HERE !
			use flashVars or xml to override
			
			all parameters explained in help file
		*/
		public var defaults:Object = {
			width: 0,
			height: 0,
			
			external: {
				font: ""
			}
		} 
		
		// holds the configuration
		public var conf:Object
		
		// dimentions
		protected var w:uint = 0
		protected var h:uint = 0
		
		// loading spinner
		protected var spinner:bitfade.ui.spinners.Spinner
		
		// constructor
		public function Xml(...args) {
			super()
			// boot the component
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// this gets called on ADDED_TO_STAGE
		public function boot(...args):void {
			// pre boot functions
			preBoot()
			// parse config
			Config.parse(this,init,args)
		}
		
		// pre boot functions
		protected function preBoot():void {
			spinner = new bitfade.ui.spinners.Circle()
			//spinner = new bitfade.ui.spinners.Circle()
		}
		
		// init component
		protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			
			if (xmlConf) {
				// override with xml conf
				conf = Misc.setDefaults(XmlParser.toObject(xmlConf),conf)
			}
			
			// set dimentions
			w = conf.width > 0 ? conf.width : stage.stageWidth
			h = conf.height > 0 ? conf.height : stage.stageHeight
			
			// called before loading external resources
			preLoadExternalResources()
			// load external resource, if needed
			Config.loadExternalResources(conf.external,resourcesLoaded)
						
		}
		
		
		// called before loading external resources
		protected function preLoadExternalResources():void {
			if (spinner) {
				spinner.x = (w-spinner.width)/2
				spinner.y = (h-spinner.height)/2
					
				addChild(spinner)
				spinner.show(0.1)
			}
		}
		
		// called when external resources are loaded
		protected function resourcesLoaded(content:* = null):void {
			if (configure()) {
				build()
				display()
			} else {
				if (spinner) spinner.hide()
				
				var console:bitfade.ui.text.TextField = new bitfade.ui.text.TextField({
					defaultTextFormat: new TextFormat("Verdana",11,0xFF0000,true),
					maxWidth: w,
					maxHeight: 64
				})
				
				console.content("No configuration defined")
				
				addChild(console)
				
				console.x = (w-console.width)/2
				console.y = (h-console.height)/2
				
			}
		}
		
		// handle configuration
		protected function configure():Boolean {
			return true
		}
		
		// build needed elements
		protected function build():void {
		}
		
		// go!
		protected function display():void {
			if (spinner) spinner.hide()
		}
		
		// resize component
		public function resize(nw:uint = 0,nh:uint = 0):void {
		}
		
		// destruct component
		public function destroy():void {
			Gc.destroy(this)
		}
		
	}
}
/* commentsOK */