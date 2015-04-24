package
{
	import away3d.controllers.ControllerBase;
	import away3d.core.base.Object3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.entities.Entity;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class SpringCameraController extends ControllerBase
	{
		public var cameraTarget:Object3D;
		/**
		 * [optional] Target object3d that camera should follow. If target is null, camera behaves just like a normal Camera3D.
		 */
		//spring stiffness
		/**
		 * Stiffness of the spring, how hard is it to extend. The higher it is, the more "fixed" the cam will be.
		 * A number between 1 and 20 is recommended.
		 */
		public var stiffness:Number=1;
		/**
		 * Damping is the spring internal friction, or how much it resists the "boinggggg" effect. Too high and you'll lose it!
		 * A number between 1 and 20 is recommended.
		 */
		public var damping:Number=4;
		/**
		 * Mass of the camera, if over 120 and it'll be very heavy to move.
		 */
		public var mass:Number=40;
		/**
		 * Offset of spring center from target in target object space, ie: Where the camera should ideally be in the target object space.
		 */
		public var positionOffset:Vector3D=new Vector3D(0, 5, -50);

		/**
		 * offset of facing in target object space, ie: where in the target object space should the camera look.
		 */
		public var lookOffset:Vector3D=new Vector3D(0, 2, 10);

		//zrot to apply to the cam
		private var _zrot:Number=0;

		//private physics members
		private var _velocity:Vector3D=new Vector3D();
		private var _dv:Vector3D=new Vector3D();
		private var _stretch:Vector3D=new Vector3D();
		private var _force:Vector3D=new Vector3D();
		private var _acceleration:Vector3D=new Vector3D();

		//private target members
		private var _desiredPosition:Vector3D=new Vector3D();
		private var _lookAtPosition:Vector3D=new Vector3D();

		//private transformed members
		private var _xPositionOffset:Vector3D=new Vector3D();
		private var _xLookOffset:Vector3D=new Vector3D();
		private var _xPosition:Vector3D=new Vector3D();

		private var _viewProjection:Matrix3D=new Matrix3D();
		private var _up:Vector3D=new Vector3D();

		public function SpringCameraController(targetObject:Entity=null)
		{
			super(targetObject);

		}

		public override function update():void
		{
			if (cameraTarget != null)
			{
				_xPositionOffset=cameraTarget.transform.deltaTransformVector(positionOffset);
				_xLookOffset=cameraTarget.transform.deltaTransformVector(lookOffset);
				var p:Vector3D=cameraTarget.position;
				_desiredPosition=p.add(_xPositionOffset);
				_lookAtPosition=p.add(_xLookOffset);

				_stretch=this.targetObject.position.subtract(_desiredPosition);
				_stretch.scaleBy(-stiffness);
				_dv=_velocity.clone();
				_dv.scaleBy(damping);
				_force=_stretch.subtract(_dv);

				_acceleration=_force.clone();
				_acceleration.scaleBy(1.0 / mass);
				_velocity=_velocity.add(_acceleration);

				_xPosition=targetObject.position.add(_velocity);
				targetObject.x=_xPosition.x;
				targetObject.y=_xPosition.y;
				targetObject.z=_xPosition.z;

				targetObject.lookAt(_lookAtPosition);


				if (Math.abs(_zrot) > 0)
				{
					//	rotate(Vector3D.Z_AXIS, _zrot);
				}

			}
		}
	}
}
