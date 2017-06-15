/*

	Particles structure builder: random

*/
package bitfade.intros.particles.structures {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Random {
		public static function build(MAX_PARTICLES:uint):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
  			
  			var dy : Number = 800/(MAX_PARTICLES)
  			var py : Number = -400
  			
  			for (var i:uint = 0;i<MAX_PARTICLES; i++,py += dy) {
  				node = p3dList.create()
  				
  				node.x = Math.random()*800-400
  				node.y = py 
  				//node.z = Math.random()*800-500
  				
  				//node.x = Math.random()*400-200
  				//node.y = Math.random()*400-200
  				
  				node.z = Math.random()*200-100
  				
  				node.life = Math.random()*300+100
  				
  				  				
  				p3dList.append(node)
  			}
			
			
			
			return p3dList
		}
	}

}