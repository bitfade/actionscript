/*

	Particles transformations: Matrix
	
	apply a 3d Matrix to a list of particles

*/
package bitfade.intros.particles.transformations {

	import flash.geom.Matrix3D

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Matrix {
		public static function apply(pFrom:LinkedListPool,mat:Matrix3D,pTo:LinkedListPool):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var nodeTo: Particle3dLife = Particle3dLife(pTo.head.next)
  			
  			var p00: Number = mat.rawData[ 0 ];
			var p01: Number = mat.rawData[ 1 ];
			var p02: Number = mat.rawData[ 2 ];
			var p10: Number = mat.rawData[ 4 ];
			var p11: Number = mat.rawData[ 5 ];
			var p12: Number = mat.rawData[ 6 ];
			var p20: Number = mat.rawData[ 8 ];
			var p21: Number = mat.rawData[ 9 ];
			var p22: Number = mat.rawData[ 10 ];
			var p30: Number = mat.rawData[ 12 ];
			var p31: Number = mat.rawData[ 13 ];
			var p32: Number = mat.rawData[ 14 ];
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					nodeTo = Particle3dLife(nodeTo.next)
  					) {
  				
  				nodeTo.x = nodeFrom.x * p00 + nodeFrom.y * p10 + nodeFrom.z * p20 + p30
  				nodeTo.y = nodeFrom.x * p01 + nodeFrom.y * p11 + nodeFrom.z * p21 + p31
  				nodeTo.z = nodeFrom.x * p02 + nodeFrom.y * p12 + nodeFrom.z * p22 + p32
  				
  				nodeTo.life = nodeFrom.life
  				
  			}
		}
	}

}