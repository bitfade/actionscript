/*

	This class is used to play videos
	extends player by adding a playlist

*/
package bitfade.media.players.playlist {
	
	import bitfade.media.players.*
	import bitfade.media.preview.playlist.*
	import bitfade.ui.frames.*
	import bitfade.media.streams.*
	import flash.display.*
	import flash.events.*
	import flash.utils.*
	
	import flash.xml.*
	import bitfade.utils.*
	import bitfade.ui.icons.*
	
	public class Player extends bitfade.media.players.Player {
	
		protected var playlistDefaults:Object = {
			cover: true
		}
		
		protected var shareDefaults:Object = {
		}
	
		// playlist variables
		protected var playlist:bitfade.media.preview.playlist.Video
		protected var playlistConf:XML
		protected var playlistControl:bitfade.ui.icons.BevelGlow
		protected var playlistOnTop:Sprite
		
		// share variables
		protected var share:bitfade.media.preview.playlist.Share
		protected var shareConf:XML
		protected var shareControl:bitfade.ui.icons.BevelGlow
		
		// hd variables
		protected var hdControl:bitfade.ui.icons.BevelGlow
		
		protected var pausedFromPlaylist:Boolean = false
		protected var delayedHidePlayOnTop:RunNode;
		
		protected var playlistIndex:int
		protected var fadeLoop:RunNode
		
		// holds the active window
		protected var activeWindow:bitfade.media.preview.playlist.Reflection
		
		// constructor
		public function Player(...args) {
			overrideDefaults()
			bitfade.utils.Boot.onStageReady(this,args)
		}
		
		protected function overrideDefaults() {
			defaults.advertise.every = 0
			defaults.controls.hd = true
			defaults.start.hd = true
			defaults.start.download = ""
			defaults.playback.hdIsLink = false
			
			// add index CSS rule to default conf
			defaults.style.text += <style><![CDATA[
				index {
					colorDark: #FFD209;
					colorLight: #466FB9;
					font-family: Sapir Sans;
					font-size: 10px;
					font-weight: bold;
					text-align: center;
				}
			]]></style>.toString()
			
			// add index CSS rule to default conf
			defaults.style.text += <style><![CDATA[
				share {
					colorDark: #FFFFFF;
					colorLight: #505050;
					font-family: Sapir Sans;
					font-size: 13px;
					text-align: center;
				}
				
				label {
					colorDark: #CCCCCC;
					colorLight: #909090;
					font-family: Sapir Sans;
					font-size: 15px;
					text-align: center;
				}
			]]></style>.toString()
			
			// tracking actions
			
			defaults.tracking = {
				videoLoadStart: "",
				videoLoadComplete: "",
				videoPlayPauseClick: "",
				playlistClick: "",
				hdClick: "",
				volumeClick: "",
				fullScreenClick: "",
				shareClick: ""
			}
			

		}
		
		
		
		override protected function init(xmlConf:XML = null,id:*=null,url:*=null):void {
			
			
			if (xmlConf) {
				if (xmlConf.hasOwnProperty("playlist")) {
					// get playlist xml conf from main conf
					playlistConf = new XML(xmlConf.playlist)
					
					delete xmlConf.playlist.item
					
					// add playlist to conf.controls
					conf.controls.playlist = true
					
					// set some other config defaults
					conf.playlist = playlistDefaults
					conf.advertise.every = 0
					
					conf.caption = {}
				
					
				}
				
				if (xmlConf.hasOwnProperty("share")) {
					// get share xml conf from main conf
					shareConf = new XML(xmlConf.share)
					delete xmlConf.playlist.item
					
					// add share to conf.controls
					conf.controls.share = true
					
					// set some other config defaults
					conf.share = shareDefaults
					
				}
			} 
			super.init(xmlConf)
		}
		
		protected function tracking(callBack:String,value:* = null):void {
			if (callBack && callBack != "") {
				if (value) callBack = callBack.replace(/\?/,value)
				ResLoader.openUrl(callBack)
			}
		}
		
		override protected function drawCustomControls():void {
			// add playlist button to bar
			if (conf.controls.playlist) {
				playlistControl = new bitfade.ui.icons.BevelGlow("playlist","playlist")
				controls.addChild(playlistControl)
			} 
			
			
			if (conf.controls.share) {
				shareControl = new bitfade.ui.icons.BevelGlowText("share","SHARE",16,42)
				controls.addChild(shareControl)
			}
			
			if (conf.controls.hd) {
				hdControl = new bitfade.ui.icons.BevelGlowText("hd","HD",16,24)
				controls.addChild(hdControl)
			}
		}
		
		protected function createPlaylistControl() {
			playlist = new bitfade.media.preview.playlist.Video(w,h,playlistConf)
		}
		
		override protected function drawOnTop():void {
			
			super.drawOnTop()
			
			if (conf.controls.playlist) {
				
				// set playlist caption height = player caption height
				playlistConf.caption = new XMLNode(1,"")
				playlistConf.caption.@height = conf.description.height
				playlistConf.caption.@margin = conf.controls.show == "always" ? 24 : 0
				
				playlistConf.caption.@scheme = conf.description.scheme 
				
				// set playlist caption style = player caption style
				//playlistConf.style.text = new XMLNode(3,setStyleColors(conf.style.text))
				playlistConf.style.text = new XMLNode(3,setStyleColors(conf.style.text is String ? conf.style.text : conf.style.text.content))
				
				playlistConf.style.@type = conf.style.type
				playlistConf.style.@transparent = conf.style.transparent
				
				// no external font loading for playlist coz we do this in player
				playlistConf.external.@font = ""
				
				// start as hidden
				playlistConf.@visible = false
				
				// create the playlist
				createPlaylistControl()
				playlist.clickHandler(playlistClick,true)
				
				playlistOnTop = new Sprite();
				
				// add the playlist controls to the overlay
				var playlistOnTopBackground:Bitmap = new Bitmap(Snapshot.take(bitfade.ui.frames.Shape.create("default."+conf.style.type,70,70,0,0,null,null,8)))
				playlistOnTopBackground.alpha = 0.4
				playlistOnTopBackground.blendMode = "hardlight"
				
				
				playlistOnTop.addChild(playlistOnTopBackground)
				
				playlistOnTopBackground = new Bitmap(playlistOnTopBackground.bitmapData)
				playlistOnTopBackground.blendMode = conf.style.type == "dark" ? "add" : "overlay"
				
				playlistOnTop.addChild(playlistOnTopBackground)
				
				playlistOnTop.addChild(playOnTop)
				
				var pControlX = int((playlistOnTopBackground.width-16*3+1)/2)
				
				var pControlIcon:bitfade.ui.icons.BevelGlow = new bitfade.ui.icons.BevelGlow("playlistPrev","prev")
				pControlIcon.x = pControlX
				pControlIcon.y = 50
				playlistOnTop.addChild(pControlIcon)
				
				pControlX += 16
				pControlIcon = new bitfade.ui.icons.BevelGlow("playlistOnTop","playlist")
				pControlIcon.x = pControlX
				pControlIcon.y = 50
				playlistOnTop.addChild(pControlIcon)
				
				pControlX += 17
				pControlIcon = new bitfade.ui.icons.BevelGlow("playlistNext","next")
				pControlIcon.x = pControlX
				pControlIcon.y = 50
				playlistOnTop.addChild(pControlIcon)
				
				onTop.addChild(playlistOnTop)
				onTop.addChild(playlist)
				onTop.addChild(spinner)
			
			}
			
			if (conf.controls.share) {
				// set playlist caption height = player caption height
				shareConf.caption = new XMLNode(1,"")
				shareConf.caption.@height = conf.description.height
				shareConf.caption.@scheme = conf.description.scheme 
				
				// set playlist caption style = player caption style
				//shareConf.style.text = new XMLNode(3,setStyleColors(conf.style.text))
				shareConf.style.text = new XMLNode(3,setStyleColors(conf.style.text is String ? conf.style.text : conf.style.text.content))
				shareConf.style.@type = conf.style.type
				shareConf.style.@transparent = conf.style.transparent
				
				// no external font loading for playlist coz we do this in player
				
				shareConf.external.@font = ""
				
				// start as hidden
				shareConf.@visible = false
				
				// create the playlist
				share = new bitfade.media.preview.playlist.Share(w,h,shareConf)
				share.clickHandler(shareNetworkClick,true)
				
				if (playlistOnTop) onTop.addChild(playlistOnTop)
				if (playlist) onTop.addChild(playlist)
				onTop.addChild(share)
				onTop.addChild(spinner)
				
			}
			
		}
		
		protected function shareNetworkClick(network:Object) {
			tracking(conf.tracking.shareClick,network.type)
			share.openUrl(network)
		}
		
		protected function selectResource(item:*,hd:String = ""):String {
		
			var selected:String
			var ld:String 
		
			if (item is String) {
				ld = item				
			} else {
				ld = item.resource
				hd = item.resourceHD
			}
			
			// select proper resource
			selected = hd && conf.start.hd ? hd : ld
		
			// save both as we need it when not using playlist
			conf.start.resourceLD = ld
			conf.start.resourceHD = hd
			
			return selected
					
		}
		
		// save link for download
		public function setDownload(link:String) {
			if (share) {
			
				var fV:String = ""
				var swfUrl:String = ""
			
				try {
					swfUrl = stage.loaderInfo.url
				} catch (e:*) {}
			
				if (conf.xml) {
					fV = "player.xml="+conf.xml
				}
				
				XML.ignoreWhitespace = XML.prettyPrinting = true
								
				share.setDownload(link)
				share.setEmbed(<object>
	<embed src={swfUrl} 
		flashvars={fV} 
		type="application/x-shockwave-flash" 
		allowscriptaccess="always" 
		allowfullscreen="true" 
		width={w} 
		height={h}
	/>
	<param name="allowFullScreen" value="true"/>
	<param name="allowscriptaccess" value="always"/>
</object>.toXMLString());
				
				

			}
		}
			
		
		override protected function startPlayer() {
			
			if (conf.start.playlist) conf.start.paused = true
			
			if (!playlist && !conf.start.resource) {
				spinner.hide()
				showMessage("No configuation defined")
			}
			
			if (!conf.start.caption) {
				// empty caption
				conf.start.caption = {}
			}
			
			// check if we have playlist items
			if (playlist && playlist.all.length > 0) {
				if (conf.start.playlist) {
					// show playlist when player loads
					showWindow(playlist)
					setDownload("")
					spinner.hide()
					
				} else {
				
					// get first item
					playlistIndex = 0
					var item:Object = playlist.all[playlistIndex]
				
					conf.start.resource = selectResource(item)
					setDownload(item.download)
					
					if (item.caption && item.caption[0].content) {
						// set caption text
						conf.start.caption.content =  item.caption[0].content
						description.alpha = 0.01
					}
					
					if (item.cover) {
						// set cover image
						conf.start.cover = item.cover
					} else {	
						conf.start.cover = ""
						spinner.hide()
						showPlayOnTop()
					}
					
					playlist.startIndex = playlistIndex
					
				}
			} else {
				// handle the case for HD without playlist
			
				// save ld resource
				conf.start.resourceLD = conf.start.resource
				conf.start.resource = selectResource(conf.start.resourceLD,conf.start.resourceHD)
				setDownload(conf.start.download)
		
			}
			
			// call parent
			super.startPlayer()	
		}
		
		
		protected function playlistClick(item:Object,showCover:Boolean = false) {
		
			// selected item caption text
			var captionText = item.caption ? item.caption[0].content : null
			conf.start.playlist = false
			playlistIndex = item.id
			
			setDownload(item.download)
			
			if (conf.advertise.playing) {
				// advertise video is ready to start so we'll set next video
				conf.start.cover = item.cover
				resource = conf.start.resource = selectResource(item)
					
				cover(conf.start.cover)
				conf.start.caption.content = captionText
				setDescription(captionText)
				
				if (showCover ? false : !conf.playlist.cover) {
					// start immediately
					resume()
					coverOnTop.visible = false
					hideDescription()
					
				}
			} else if (item.resource != resource) {
				
				// check if we need to repeat advertise
				if (conf.advertise.every > 0 && (getTimer() - conf.advertise.started)/1000 > conf.advertise.every) {
					conf.advertise.done = false
					conf.start.resource = selectResource(item)
					
					load(conf.advertise.resource,item.cover,captionText,showCover ? false : !conf.playlist.cover)
					conf.start.caption.content = captionText
				} else {
					// load selected item resource
					load(selectResource(item),item.cover,captionText,showCover ? false : !conf.playlist.cover)
					
				}				
			} else {
				// unpause playback if paused previously
				if (pausedFromPlaylist) resume()
			}
			
			if (playlist.visible) {
				// hide playlist
				showWindow()
				playlist.startIndex = item.id
			}
		}
		
		override protected function resizeControls():void {
			super.resizeControls()
			
			if (!(playlistControl || hdControl || shareControl)) return
			
			var i = controls.numChildren
			
			var extControl:DisplayObject
			var shiftAmount:uint = 0
			
			
			if (hdControl) {
				i--
				shiftAmount += hdControl.width+4
				hdControl.x = w-shiftAmount
				hdControl.y = 4
			}
			
			if (shareControl) {
				i--
				shiftAmount += shareControl.width+4
				shareControl.x = w-shiftAmount
				shareControl.y = 4
				
			}
			
			if (playlistControl) {
				i--
				shiftAmount += playlistControl.width
				playlistControl.x = w-shiftAmount-4
				playlistControl.y = 4
			}
			
			// position the playlist control on the bar by shifting existing controls
			while (i-- > 3) {
				extControl = controls.getChildAt(i)
				if (extControl == statusCaption) continue
				if (extControl == seekBar ) {
					extControl.width -= shiftAmount
				} else {
					extControl.x -= shiftAmount
				}				
			}
			
			// position playlist overlay controls
			if (playlistOnTop) {
				playOnTop.x = int((playlistOnTop.getChildAt(0).width-playOnTop.width)/2)
				playOnTop.y = 0
				playlistOnTop.x = int((w-playlistOnTop.width)/2)
				playlistOnTop.y = int((visualHeight-playlistOnTop.height)/2)+10
			}
			
		}
		
		override public function resize(nw:uint = 0,nh:uint = 0):void {
			if (!conf) return
			super.resize(nw,nh)
			// resize playlist
			if (playlist) playlist.resize(nw,nh)
			if (share) share.resize(nw,nh)
		}
		
		override protected function watermarkLoaded(wmark:*):void {
			if (!wmark) return
			super.watermarkLoaded(wmark) 
			// playlist goes above watermark
			if (playlist) onTop.swapChildren(watermark,playlist)
		}
		
		// hide main elements for handling transparency
		protected function fadeLoopRunner(ratio:Number,show:Boolean) {
			ratio = show ? ratio : 1 - ratio
			description.alpha = coverOnTop.alpha = playlistOnTop.alpha = playOnTop.alpha = frame.alpha = ratio
		}
		
		protected function showWindow(target:bitfade.media.preview.playlist.Reflection = null) {
					
			var other:bitfade.media.preview.playlist.Reflection
			
			if (target) {
				other = (target == playlist) ? share : playlist
				target.show()
				
				if (conf.style.transparent > 0 && frame.alpha == 1) {
					fadeLoop = Run.every(Run.FRAME,fadeLoopRunner,8,0,true,fadeLoop,false)
				}
				
			} else if (activeWindow) {
				activeWindow.hide()
				
				if (conf.style.transparent > 0) {
					fadeLoop = Run.every(Run.FRAME,fadeLoopRunner,8,0,true,fadeLoop,true)
				}
				
			}
			
			activeWindow = target
	
			if (other && other.visible) {
				Run.after(0.2,other.hide)
				//other.hide()
				if (onTop.getChildIndex(target) < onTop.getChildIndex(other)) onTop.swapChildren(target,other)
			}
			
			enlightActive()
			
		}
		
		override protected function evHandler(e:*):void {
			
			var id:String = e.target.name
		
			switch (e.type) {
				case MouseEvent.MOUSE_DOWN:
						switch (id) {
						case "playlistOnTop":
						case "playlist":
							tracking(conf.tracking.playlistClick)
							if (playlist.visible) {
								// hide playlist
								if (!conf.start.playlist) {
									if (pausedFromPlaylist) resume()
									showWindow()
								}
							} else {
								if (controlStream.paused || !(conf.advertise.playing && conf.advertise.disablePause)) {
									// show playlist and pause video
									if (controlStream.paused) {
										pausedFromPlaylist = false
									} else {
										pausedFromPlaylist = true
										pause()
									}
									playlist.startIndex = playlistIndex
									showWindow(playlist)
															
								}
							}
						break;
						case "share":
							if (share.visible) {
								if (playlist && !conf.start.resourceLD) {
									// show playlist again coz we still have no user selected video
									showWindow(playlist)
								} else {
									if (pausedFromPlaylist) resume()
									showWindow()
								}
							
							} else {
								if (controlStream && (controlStream.paused || !(conf.advertise.playing && conf.advertise.disablePause))) {
									// show playlist and pause video
									if (controlStream.paused) {
										pausedFromPlaylist = false
									} else {
										pausedFromPlaylist = true
										pause()
									}
									showWindow(share)
								}							
							}
						break
						case "playlistNext":
						case "playlistPrev":
							// load next playlist item
							loadNext(id == "playlistPrev")
						break;
						case "hd":
							tracking(conf.tracking.hdClick)
							if (!conf.playback.hdIsLink) {
								conf.start.hd = !conf.start.hd
								if (conf.start.resourceLD) {
									if (conf.advertise.playing) {
										// advertise video is ready to start so we'll set next video
										conf.start.resource = selectResource(conf.start.resourceLD,conf.start.resourceHD)
									} else {
										load(selectResource(conf.start.resourceLD,conf.start.resourceHD),null,null,true)
									}
								}
								
								enlightActive()
							} else {
								ResLoader.openUrl(conf.start.resourceHD,"_new")
							}
							
						break
						case "volume":
						case "volumeBar":
							tracking(conf.tracking.volumeClick)
							super.evHandler(e)
						break;
						case "fullscreen":
							tracking(conf.tracking.fullScreenClick)
							super.evHandler(e)
						break;
						default:
							super.evHandler(e)
					}
				break
				case MouseEvent.MOUSE_OUT:
					switch (id) {
						case "hd":
						case "share":
						case "playlist":
							enlightActive()
						break;
						default:
							super.evHandler(e)
					}
				break;
				default:
					super.evHandler(e)
			}
		}
		
		// keep enlight on active controls
		protected function enlightActive() {
			if (hdControl) hdControl.over(conf.start.hd)
			if (playlistControl) playlistControl.over(activeWindow == playlist)
			if (shareControl) shareControl.over(activeWindow == share)
		}
		
		override public function load(...args):void {
			if (!conf) return
			super.load.apply(null,args)
			// if immediate start
			if (args[3] == true) {
				showWindow()
			}
			enlightActive()
		}
		
		
		override protected function streamEventHandler(e:StreamEvent):void {
			switch (e.type) {
				case StreamEvent.CONNECT:
					tracking(conf.tracking.videoLoadStart,controlStream.resource)
				break;
				case StreamEvent.PAUSE:
				case StreamEvent.RESUME:
					tracking(conf.tracking.videoPlayPauseClick,controlStream.resource)
				break;
				case StreamEvent.STOP:
					tracking(conf.tracking.videoLoadComplete,controlStream.resource)
				break;
			}
			super.streamEventHandler(e)
		}
		
		// load prev/next playlist item
		public function loadNext(prev:Boolean = false,showCover:Boolean = true) {
			if (coverLoading) return
			playlist.advance(prev ? -1 : +1)
			playlistClick(playlist.all[playlist.startIndex],showCover)
		}
		
		protected function hidePlayOnTop() {
			playOnTop.visible = false
		}
		
		override public function cover(url:String):void {
			if (!conf || !url) return
			super.cover(url)
			delayedHidePlayOnTop = Run.after(0.1,hidePlayOnTop,delayedHidePlayOnTop,false)
		}
		
		override protected function coverLoaded(image:*,id:*=null,url:*=null):void {
			super.coverLoaded(image,id,url)
			Run.reset(delayedHidePlayOnTop)
		}
		
		override protected function showPlayOnTop():void {
			super.showPlayOnTop()
			if (playlist) playlistOnTop.visible = playOnTop.visible
		}
		
		override public function volume(vol:Number,save:Boolean = true):void {
			vol = range01(vol)
			super.volume(vol,save)
			if (playlist) playlist.volume(vol)
		}
		
		override protected function fireEvent(type:String,value:Number = -1):void {
			super.fireEvent(type,value)
			switch (type) {
				case PlayerEvent.PLAY:
					showWindow()
				break;
				case PlayerEvent.STOP:
					
					if (!playlist) break;
					
					var onStop:String = conf.playback.onStop
					
					var tokens = onStop.split(":")
					onStop = tokens[0]
					var loop:Boolean = (tokens[1] == "loop")
					
					switch (onStop) {
						case "playlist":
							showWindow(playlist)
						break;
						case "share":
							showWindow(share)
						break;
						case "next":
						case "nextAutoPlay":
							if (!loop && playlist.startIndex == playlist.all.length-1) {
								// no loop, last item -> show playlist 
								showWindow(playlist)
							} else if (onStop == "next") {
								loadNext()
							} else {
								var saved:Boolean = conf.playlist.cover 
								conf.playlist.cover = false
								loadNext(false,false)
								conf.playlist.cover = saved
							}
						break;
					}
				break;
				
			}
		}
	}
}
/* commentsOK */