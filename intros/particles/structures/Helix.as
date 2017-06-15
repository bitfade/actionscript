/*

	Particles structure builder: Helix

*/
package bitfade.intros.particles.structures {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Helix {
		public static function build(MAX_PARTICLES:uint):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
  			
  			var dy : Number = 800/(MAX_PARTICLES)
  			var py : Number = -400
  			var angle: Number = 0
  			
  			var radMin:Number = -50
  			var radMax:Number = 50
  			
  			var radPart:uint = 10
  			var radIncr:uint = 1
  			var radDelta:Number = (radMax-radMin)/(radPart-1)
  			var radP:Number = radMin
  			
  			
  			for (var i:uint = 0;i<MAX_PARTICLES; i++,py += dy) {
  				node = p3dList.create()
  				
  				angle = (i*Math.PI)/MAX_PARTICLES
  				
  				node.x = radP*Math.sin(angle*5)
  				node.y = py
  				node.z = radP*Math.cos(angle*5)
  				
  				
  				
  				node.life = Math.random()*400+100
  				
  				if (radIncr < radPart) {
  					radP += radDelta
  					radIncr ++
  				} else {
  					radP = radMin
  					radIncr = 1
  	
  				}
  				  				
  				p3dList.append(node)
  			}
			
			
			
			return p3dList
		}
	}

}