/*

	Implements addThis interface
	
*/
package bitfade.media.preview.playlist {	
	
	import bitfade.media.preview.playlist.Reflection
	import flash.display.*
	import flash.events.*
	import flash.text.*
	
	import bitfade.utils.*
	import bitfade.ui.text.*
	import bitfade.ui.core.*
	import bitfade.ui.thumbs.Thumb
	import bitfade.ui.icons.BevelGlowText
	
	import flash.external.ExternalInterface;
 
	
	public class Share extends bitfade.media.preview.playlist.Reflection  {
		
		// video preview component
		protected var selectedThumb:bitfade.ui.thumbs.Thumb
		
		// download button
		protected var download:bitfade.ui.icons.BevelGlowText
		protected var downloadLink:String
		
		// embed button
		protected var embed:bitfade.ui.icons.BevelGlowText
		protected var embedText:bitfade.ui.text.TextField
		protected var embedTextValue:String
		
		protected var embedFadeLoop:RunNode
		
		public function Share(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		// override defaults for parent, since we are using small icons
		override protected function overrideDefaults():void {
			super.overrideDefaults()
			
			defaults.thumbs = {
				width: 32,
				height: 32,
				scale: "none",
				align: "center,center",
				frame: 0,
				enlight: 4,
				margins: "0,0",
				spacing: 4,
				horizMargin: 100
			}
			
			defaults.reflection = {
				enabled: true,
				falloff: 20,
				alpha: 20,
				offset: 20
			}
			
			defaults.embed = {
				show: false,
				button: "EMBED CODE",
				label: "RIGHT CLICK HERE, THEN CLICK COPY"
			}
			
			defaults.settings = {
				button: "DOWNLOAD THIS VIDEO",
				icons: "resources/addThis",
				label: "Share this Video Player<br>(Select Social Network)<br><br>",
				
				username: "",
				
				embedSwf: "false",
				
				url: "",
				swfurl: "",
				width: "",
				height: "",
				title: "",
				description: "",
				screenshot: ""
				
			}
			
			defaults.scrollBar.show = "never"
		}
		
		// set download link
		public function setDownload(link:String) {
			download.visible = Boolean(link) 
			downloadLink = link
			localResize()
		}
		
		// set embed text
		public function setEmbed(text:String) {
			embedTextValue = text
		}
		
		public function onClick(cb:Function) {
		}
		
		override protected function addIds() {
			
			super.addIds()
			
			// try to get page url
			if (!conf.settings.url) {
				try {
					conf.settings.url = ExternalInterface.call('window.location.href.toString');
				} catch (e:*) {}
			}
			
			if (conf.settings.embedSwf) {
				conf.settings.swfurl = stage.loaderInfo.url
			}
			
			var idx:uint = items
			var item:Object
			
			var fields:Array = ["embedSwf","username","url","swfurl","width","height","title","description","screenshot"]
			var prop:String
			
			// for each configure network, add defaults values
			while(idx--) {
				item = conf.item[idx]
				item.link = "share"
				
				for each (prop in fields) {
					if (!item[prop]) item[prop] = conf.settings[prop]
				}
				
				if (item.embedSwf == "false") {
					delete item.swfurl
				} 
				delete item.embedSwf
				
			}
		}
		
		override protected function initDisplay(...args):void {
			
			super.initDisplay.apply(null,args)
				
			// new
			bitfade.ui.icons.BevelGlowText.setStyle(conf.style.type)
			
			if (conf.embed.show) {
				// create embed text field
				embed = new bitfade.ui.icons.BevelGlowText("embed",conf.embed.button,24,140)	
				embedText = new bitfade.ui.text.TextField({
					// 0xA0A0A0
					defaultTextFormat: new TextFormat("PF Tempesta Seven Condensed_8pt_st",8,conf.style.type == "dark" ? 0x808080 : 0x404040),
					selectable: true,
					maxWidth : w,
					mouseEnabled: true,
					alwaysShowSelection: true,
					autoSize: "none",
					visible: false,
					name: "embedText"
				})
				
				addChild(embedText)
				
				// create embed text
				bitfade.utils.Events.add(embedText,[MouseEvent.CLICK,Event.SCROLL],hideEmbedText,this)
				addChild(embed)
			}
			
			// add the download button
			download = new bitfade.ui.icons.BevelGlowText("download",conf.settings.button,24,140)
			addChild(download)
			description()
			localResize()
			
		}
		
		protected function hideEmbedText(e:*) {
			if (e.type == Event.SCROLL) {
				if (embedText.scrollV > 1) {		
					embedText.scrollV = 1
				} 
			}
			showEmbed(false)
		}
		
		// show embed text
		public function showEmbed(sw:Boolean = true) {
			if ((embedText.visible == sw) ) return
			embedFadeLoop = Run.every(Run.FRAME,embedFadeLoopRunner,8,0,true,embedFadeLoop,sw)
		}
		
		override public function show(sw:Boolean = true) {
			if (locked || (visible == sw) ) return
			if (!sw && embedText) showEmbed(false)
			super.show(sw)
			
		}
		
		
		// loop for switching from buttons to embed text
  		protected function embedFadeLoopRunner(ratio:Number,show:Boolean) {
  			ratio = show ? ratio : 1-ratio
  			embedText.alpha = ratio
  			embedText.visible = (embedText.alpha > 0)
  			
  			embed.alpha = 1-ratio
  			embed.visible = (embed.alpha > 0)
  			
  			if (downloadLink) {
  				download.alpha = embed.alpha
  				download.visible = embed.visible
  			}
  		}
		
		override public function description(msg:String = null) {
			
			var shareMsg : String = "<label>"+(conf.settings.label is String ? conf.settings.label : conf.settings.label.content)+"<label>"
			
			if (msg) {
				shareMsg += "<share>"+ conf.item[msg].type+"</share>" 
			}
			
			super.description(shareMsg)
			
			caption.y = h-bottom-120
		}
		
		override protected function localResize():void {
			super.localResize()
			caption.y = h-bottom-120
			
			prev.x = conf.thumbs.horizMargin-conf.thumbs.width
			next.x = offs-conf.thumbs.horizMargin+conf.thumbs.width-next.width
			
			if (download) {
				download.y = h+int((conf.caption.height-24-download.height)/2)
				download.x = int((w-download.width)/2)
			}
			
			if (embed) {
				embed.y = h+int((conf.caption.height-24-download.height)/2)
				embed.x = int((w-download.width)/2)
				
				if (embed && download && download.visible) {
					var shift: uint = Math.max(download.width/2,embed.width/2)+5
					download.x -= shift
					embed.x += shift
				}
			
				
				embedText.y = h+7
				embedText.width = 210
				embedText.height = 30
			}
			
		}
		
		override protected function evHandler(e:*):void {
			super.evHandler(e)
			if (e.target is bitfade.ui.thumbs.Thumb) {
				switch (e.type) {
					case MouseEvent.MOUSE_OVER:
					case MouseEvent.MOUSE_OUT:
						if (e.type == MouseEvent.MOUSE_OVER) {
							// mouse over thumb, show preview after 0.5s
							selectedThumb = e.target
							description(selectedThumb.name)
						} else {
							// mouse out, hide preview
							description()
						}
					break;
					case MouseEvent.MOUSE_DOWN:
						// click, hide preview
						e.target.over(false)
					break;
				}
			} else if (e.target is bitfade.ui.core.IMouseOver) {
				switch (e.type) {
					case MouseEvent.MOUSE_OVER:
					case MouseEvent.MOUSE_OUT:
						e.target.over(e.type == MouseEvent.MOUSE_OVER)
					break;
					case MouseEvent.MOUSE_DOWN:
						switch (e.target.name) {
							case "download":
								ResLoader.openUrl(downloadLink,"_blank")
							break;
							case "embedText":
							case "embed":
								if (embedTextValue) {
									showEmbed()					
									embedText.text = "\n"+conf.embed.label+"\n\n\n\n\n\n\n\n\n"+embedTextValue
									embedText.x = int((w-embedText.textWidth)/2)+20
				
									stage.focus = embedText;
									embedText.setSelection(embedText.text.indexOf("<object>"),embedText.text.length);
									embedText.scrollH = embedText.scrollV = 0
								}
							break;
						}
					break
				}
			}
		}
		
		override public function openUrl(item:Object) {
			AddThis.share(item)
		}
		
	
		override protected function loadResource(thumb:bitfade.ui.thumbs.Thumb,item:Object) {
			thumb.load(conf.settings.icons + "/" + item.type + "_32.png")
		}
	}
	
}
/* commentsOK */