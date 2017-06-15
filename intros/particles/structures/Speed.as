/*

	Particles structure builder: Speed
	
	this build a list of particles which can be used to represent x,y,z speed

*/
package bitfade.intros.particles.structures {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Speed {
		public static function build(MAX_PARTICLES:uint):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
  			
  			for (var i:uint = 0;i<MAX_PARTICLES; i++) {
  				node = p3dList.create()
  				
  				node.x = Math.random()*2-1
  				node.y = -Math.random()*1
  				node.z = Math.random()
  				
  				node.life = Math.random()*4
  				
  				  				
  				p3dList.append(node)
  			}
			
			
			
			return p3dList
		}
	}

}