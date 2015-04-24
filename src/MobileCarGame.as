package
{
	import Model.Skybox;

	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.controllers.CharacterFollowController;
	import away3d.controllers.FirstPersonController;
	import away3d.controllers.FollowController;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.lights.DirectionalLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.OutlineMethod;
	import away3d.materials.methods.TerrainDiffuseMethod;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.primitives.SkyBox;
	import away3d.textures.BitmapTexture;

	import awayphysics.collision.dispatch.AWPCollisionObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.dynamics.vehicle.AWPRaycastVehicle;
	import awayphysics.dynamics.vehicle.AWPVehicleTuning;
	import awayphysics.dynamics.vehicle.AWPWheelInfo;
	import awayphysics.extend.AWPTerrain;

	import com.controls.Joystick;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;

	//[SWF(backgroundColor="#000000", width='600', height='480', backgroundColor='#000000', frameRate='60')]
	[SWF(backgroundColor="#000000", width='960', height='540', backgroundColor='#000000', frameRate='60')]
	//[SWF(backgroundColor="#000000", width='1280', height='800', backgroundColor='#000000', frameRate='60')]
	//[SWF(backgroundColor="#000000", width='1024', height='575', backgroundColor='#000000', frameRate='60')]
	public class MobileCarGame extends Sprite
	{
		//private static const CAR_OBJ:String = '../assets/car.obj';
		private static const CAR_OBJ:String='assets/dodge_challenger.obj';
		private static const MAX_ELEVATION:Number=15200;
		private static const TERRAIN_HEIGHT:Number=1200;

		private static const CAR_DROP_HEIGHT:Number=TERRAIN_HEIGHT + 100;
		private static const TERRAIN_SIZE:Number=50000;
		private static const CAMERA_CHASE_ANGLE_Y:Number=3;
		private static const WHEEL_RADIUS:Number=100;
		private static const CAMERA_SPEED:Number=0.85;
		private static const SUSPENSION_AMPLITUDE:Number=20;
		private static const ENGINE_FORCE:Number=34000;

		/*	[Embed(source="assets/embeds/fskin.jpg")]
			private var CarSkin:Class;*/
		[Embed(source="assets/embeds/Heightmap.jpg")]
		private var HeightMap:Class;
		[Embed(source="assets/embeds/terrain_tex.jpg")]
		private var Albedo:Class;
		[Embed(source="assets/embeds/terrain_norms.jpg")]
		private var Normals:Class;
		[Embed(source="assets/embeds/grass.jpg")]
		private var Grass:Class;
		[Embed(source="assets/embeds/rock.jpg")]
		private var Rock:Class;
		[Embed(source="assets/embeds/beach.jpg")]
		private var Beach:Class;
		[Embed(source="assets/embeds/grass.jpg")]
		private var Blend:Class;
		private var _view:View3D;
		private var _light:DirectionalLight;

		private var cameraController:HoverController;
		private var characterFollowController:CharacterFollowController;
		private var followController:FollowController;
		private var fpsController:FirstPersonController;

		//private var carMaterial : TextureMaterial;
		private var carMaterial:ColorMaterial;
		private var wheelMaterial:ColorMaterial;
		private var lightPicker:StaticLightPicker;
		private var physicsWorld:AWPDynamicsWorld;
		private var timeStep:Number=1.0 / 60;
		private var car:AWPRaycastVehicle;
		private var _engineForce:Number=0;
		private var _breakingForce:Number=0;
		private var _vehicleSteering:Number=0;
		private var keyRight:Boolean=false;
		private var keyLeft:Boolean=false;

		private var joystick:Joystick;

		public function MobileCarGame()
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event=null):void
		{
			stage.align=StageAlign.TOP_LEFT;
			stage.scaleMode=StageScaleMode.NO_SCALE;

			removeEventListener(Event.ADDED_TO_STAGE, init);

			_view=new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));

			joystick=new Joystick(30, 30, null);
			this.addChild(joystick);

			_light=new DirectionalLight();
			_light.y=100;
			_view.scene.addChild(_light);

			lightPicker=new StaticLightPicker([_light]);

			_view.camera.lens.far=20000;
			//_view.camera.y=500;
			//_view.camera.z=-500;
			//_view.camera.rotationX=40;

			//cameraController=new HoverController(_view.camera, null, 45, 30, 650, -10, 10, -10, 10);
			//followController=new FollowController(_view.camera, null, 30, 2000);
			//fpsController=new FirstPersonController(_view.camera);

			// init the physics world
			physicsWorld=AWPDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();

			var terrainMethod:TerrainDiffuseMethod=new TerrainDiffuseMethod([new BitmapTexture(new Beach().bitmapData), new BitmapTexture(new Beach().bitmapData), new BitmapTexture(new Rock().bitmapData)], new BitmapTexture(new Blend().bitmapData), [1, 150, 100, 50]);

			var bmaterial:TextureMaterial=new TextureMaterial(new BitmapTexture(new Albedo().bitmapData));
			bmaterial.diffuseMethod=terrainMethod;
			bmaterial.normalMap=new BitmapTexture(new Normals().bitmapData);
			bmaterial.ambientColor=0x202030;
			bmaterial.specular=.9;

			var material:ColorMaterial=new ColorMaterial(0xfc6a11);
			var whitematerial:ColorMaterial=new ColorMaterial(0xCCCCCC);
			whitematerial.lightPicker=lightPicker;
			//whitematerial.shadowMethod=new FilteredShadowMapMethod(_light);

			/*var groundmaterial:ColorMaterial=new ColorMaterial(0xCCCCCC);
			groundmaterial.lightPicker=lightPicker;
			var ground:Mesh=new Mesh(new PlaneGeometry(TERRAIN_SIZE, TERRAIN_SIZE), groundmaterial);
			ground.y=0;
			// create ground shape and rigidbody
			var groundShape:AWPStaticPlaneShape=new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody=new AWPRigidBody(groundShape, ground, 0);
			groundRigidbody.y=0;
			physicsWorld.addRigidBody(groundRigidbody);
			_view.scene.addChild(ground);*/

			// create the terrain mesh
			var terrainBMD:Bitmap=new HeightMap();
			var terrain:AWPTerrain=new AWPTerrain(bmaterial, terrainBMD.bitmapData, TERRAIN_SIZE, TERRAIN_HEIGHT, TERRAIN_SIZE, 120, 120, MAX_ELEVATION, 0, false);
			//var terrain:AWPTerrain=new AWPTerrain(whitematerial, terrainBMD.bitmapData, 50000, 1200, 50000, 120, 120, 15200, 0, false);
			terrain.castsShadows=true;
			_view.scene.addChild(terrain);
			// create the terrain shape and rigidbody
			material.lightPicker=lightPicker;
			var terrainShape:AWPHeightfieldTerrainShape=new AWPHeightfieldTerrainShape(terrain);
			var terrainBody:AWPRigidBody=new AWPRigidBody(terrainShape, terrain, 0);
			physicsWorld.addRigidBody(terrainBody);

			// create rigidbodies
			var mesh:Mesh;
			// var shape:AWPShape;
			var body:AWPRigidBody;

			//carMaterial  = new TextureMaterial(new BitmapTexture(new CarSkin().bitmapData));
			carMaterial=new ColorMaterial(0x444444);
			//carMaterial.shadowMethod=new FilteredShadowMapMethod(_light);
			//carMaterial.diffuseMethod=new CelDiffuseMethod();
			//carMaterial.specularMethod=new CelSpecularMethod(8);
			//carMaterial.addMethod(new OutlineMethod(0x111111, 1, false));
			carMaterial.lightPicker=lightPicker;
			//carMaterial.specular=0;

			wheelMaterial=new ColorMaterial(0x000000);
			//wheelMaterial.lightPicker=lightPicker;
			//wheelMaterial.diffuseMethod=new CelDiffuseMethod();
			//wheelMaterial.specular=0;

			//createCones(mesh, material, body);

			//load car model
			Parsers.enableAllBundled();
			var _loader:Loader3D=new Loader3D();
			_loader.load(new URLRequest(CAR_OBJ));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onCarResourceComplete);

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);

			createPanorama();

		}

		private function createPanorama():void
		{
			var skybox:Skybox=new Skybox(false);
			_view.scene.addChild(new SkyBox(skybox.bitmapCubeTexture));
		}

		private var windowsMesh:Mesh;
		private var windowsMaterial:ColorMaterial=new ColorMaterial(0xCCCC, .5);
		private var interiorMesh:Mesh;
		private var interiorMaterial:ColorMaterial=new ColorMaterial(0x333333);
		private var dodgeSignMesh:Mesh;
		private var dodgeSignMaterial:ColorMaterial=new ColorMaterial(0x00CCFF);
		private var exhaustMesh:Mesh;
		private var frontMesh:Mesh;

		private var brakeMaterial:ColorMaterial=new ColorMaterial(0x00FFCC);
		private var brakeRLMesh:Mesh;
		private var brakeRRMesh:Mesh;
		private var brakeFLMesh:Mesh;
		private var brakeFRMesh:Mesh;

		private function onCarResourceComplete(event:LoaderEvent):void
		{
			var container:ObjectContainer3D=ObjectContainer3D(event.target);
			_view.scene.addChild(container);
			var mesh:Mesh;
			brakeMaterial.lightPicker=lightPicker;

			for (var i:int=0; i < container.numChildren; i++)
			{
				//mesh.castsShadows=true;
				mesh=Mesh(container.getChildAt(i));
				trace(i + " mesh: " + mesh.name);
				if (i == 1)
				{
					interiorMaterial.lightPicker=lightPicker;
					interiorMesh=new Mesh(mesh.geometry, interiorMaterial);
					_view.scene.addChild(interiorMesh);
				}
				if (i == 3)
				{
					dodgeSignMesh=new Mesh(mesh.geometry, dodgeSignMaterial);
					_view.scene.addChild(dodgeSignMesh);
				}
				if (i == 4)
				{
					brakeFRMesh=new Mesh(mesh.geometry, brakeMaterial);
					_view.scene.addChild(brakeFRMesh);
				}
				if (i == 5)
				{
					frontMesh=new Mesh(mesh.geometry, dodgeSignMaterial);
					_view.scene.addChild(frontMesh);
				}
				if (i == 6)
				{
					brakeRRMesh=new Mesh(mesh.geometry, brakeMaterial);
					_view.scene.addChild(brakeRRMesh);
				}
				if (i == 8)
				{
					exhaustMesh=new Mesh(mesh.geometry, dodgeSignMaterial);
					_view.scene.addChild(exhaustMesh);
				}
				if (i == 9)
				{
					characterFollowController=new CharacterFollowController(_view.camera, mesh, 170, 500, CAMERA_SPEED, 250, CAMERA_CHASE_ANGLE_Y);
				}
				if (i == 10)
				{
					brakeRLMesh=new Mesh(mesh.geometry, brakeMaterial);
					_view.scene.addChild(brakeRLMesh);
				}
				if (i == 11)
				{
					windowsMaterial.lightPicker=lightPicker;
					windowsMesh=new Mesh(mesh.geometry, windowsMaterial);
					_view.scene.addChild(windowsMesh);
				}
				else if (i == 2 || i == 7 || i == 12 || i == 13)
				{
					mesh.material=wheelMaterial;
				}
				if (i == 14)
				{
					brakeFLMesh=new Mesh(mesh.geometry, brakeMaterial);
					_view.scene.addChild(brakeFLMesh);
				}
				else
				{
					mesh.material=carMaterial;
				}
				mesh.geometry.scale(100);
			}



			// create the chassis body
			var carShape:AWPCompoundShape=createCarShape();
			var carBody:AWPRigidBody=new AWPRigidBody(carShape, container.getChildAt(9), 2800);
			carBody.activationState=AWPCollisionObject.DISABLE_DEACTIVATION;
			carBody.linearDamping=0.5;
			carBody.angularDamping=0.5;
			physicsWorld.addRigidBody(carBody);


			// create vehicle
			var turning:AWPVehicleTuning=new AWPVehicleTuning();
			turning.frictionSlip=.1;
			turning.suspensionStiffness=100;
			turning.suspensionDamping=0.85;
			turning.suspensionCompression=0.83;
			turning.maxSuspensionTravelCm=SUSPENSION_AMPLITUDE;
			turning.maxSuspensionForce=2000;
			car=new AWPRaycastVehicle(turning, carBody);
			physicsWorld.addVehicle(car);
			trace("wheel : " + container.getChildAt(7).maxY + " / " + container.getChildAt(7).minY);
			trace("body x: " + container.getChildAt(9).maxX + " / " + container.getChildAt(9).minX);
			trace("body y: " + container.getChildAt(9).maxY + " / " + container.getChildAt(9).minY);
			trace("body z: " + container.getChildAt(9).maxZ + " / " + container.getChildAt(9).minZ);

			// add four wheels
			car.addWheel(container.getChildAt(7), new Vector3D(-90, 40, 160), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, WHEEL_RADIUS, turning, true);
			car.addWheel(container.getChildAt(2), new Vector3D(90, 40, 160), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, WHEEL_RADIUS, turning, true);
			car.addWheel(container.getChildAt(13), new Vector3D(-90, 40, -150), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, WHEEL_RADIUS, turning, false);
			car.addWheel(container.getChildAt(12), new Vector3D(90, 40, -150), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 50, WHEEL_RADIUS, turning, false);

			for (i=0; i < car.getNumWheels(); i++)
			{
				var wheel:AWPWheelInfo=car.getWheelInfo(i);
				wheel.wheelsDampingRelaxation=1.5;
				wheel.wheelsDampingCompression=1.5;
				wheel.suspensionRestLength1=SUSPENSION_AMPLITUDE;
				wheel.rollInfluence=0.01;
			}
			_engineForce=2500;
			resetCarPos();
		}

		// create chassis shape
		private function createCarShape():AWPCompoundShape
		{
			/*var boxShape1:AWPBoxShape=new AWPBoxShape(220, 155, 520);
			var carShape:AWPCompoundShape=new AWPCompoundShape();
			carShape.addChildShape(boxShape1, new Vector3D(0, 62, 0), new Vector3D());*/

			var boxShape1:AWPBoxShape=new AWPBoxShape(260, 100, 570);
			var boxShape2:AWPBoxShape=new AWPBoxShape(240, 60, 300);

			var carShape:AWPCompoundShape=new AWPCompoundShape();
			carShape.addChildShape(boxShape1, new Vector3D(0, 50, 0), new Vector3D());
			carShape.addChildShape(boxShape2, new Vector3D(0, 60, -30), new Vector3D());

			return carShape;
		}

		private function resetCarPos():void
		{
			car.getRigidBody().rotation=new Vector3D(0, 0, 0);
			car.getRigidBody().position=new Vector3D(0, CAR_DROP_HEIGHT, 0);
		}

		private function keyDownHandler(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
					_engineForce=ENGINE_FORCE;
					_breakingForce=0;
					break;
				case Keyboard.DOWN:
					_engineForce=-ENGINE_FORCE;
					_breakingForce=0;
					break;
				case Keyboard.LEFT:
					keyLeft=true;
					keyRight=false;
					break;
				case Keyboard.RIGHT:
					keyRight=true;
					keyLeft=false;
					break;
				case Keyboard.F:
					/*if (stage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE)
					{
						stage.displayState=StageDisplayState.FULL_SCREEN_INTERACTIVE;
					}
					else
					{
						stage.displayState=StageDisplayState.NORMAL;
					}*/
					break;
				case Keyboard.SPACE:
					_breakingForce=ENGINE_FORCE / 2;
					_engineForce=0;
					break;
				case Keyboard.R:
					resetCarPos();
					break;
			}
		}


		private function keyUpHandler(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
					_engineForce=0;
					break;
				case Keyboard.DOWN:
					_engineForce=0;
					break;
				case Keyboard.LEFT:
					keyLeft=false;
					break;
				case Keyboard.RIGHT:
					keyRight=false;
					break;
				case Keyboard.SPACE:
					_breakingForce=0;
			}
		}


		private function handleEnterFrame(e:Event):void
		{
			physicsWorld.step(timeStep);

			if (keyLeft)
			{
				_vehicleSteering-=0.1;
				if (_vehicleSteering < -Math.PI / 6)
				{
					_vehicleSteering=-Math.PI / 6;
				}
			}
			if (keyRight)
			{
				_vehicleSteering+=0.1;
				if (_vehicleSteering > Math.PI / 6)
				{
					_vehicleSteering=Math.PI / 6;
				}
			}

			if (car)
			{
				// control the car
				car.applyEngineForce(_engineForce, 0);
				car.setBrake(_breakingForce, 0);
				car.applyEngineForce(_engineForce, 1);
				car.setBrake(_breakingForce, 1);
				car.applyEngineForce(_engineForce, 2);
				car.setBrake(_breakingForce, 2);
				car.applyEngineForce(_engineForce, 3);
				car.setBrake(_breakingForce, 3);

				car.setSteeringValue(_vehicleSteering, 0);
				car.setSteeringValue(_vehicleSteering, 1);
				_vehicleSteering*=0.9;

				positionBodyPart(windowsMesh);
				positionBodyPart(interiorMesh);
				positionBodyPart(dodgeSignMesh);
				positionBodyPart(exhaustMesh);
				positionBodyPart(frontMesh);

				//trace(car.getRigidBody().position.y + " / " + car.getWheelInfo(0).worldPosition.y);

				//brakeFLMesh.position=new Vector3D(car.getRigidBody().position.x, car.getWheelInfo(0).worldPosition.y / 100 + car.getRigidBody().y, car.getRigidBody().position.z);
				positionBrake(brakeFLMesh);
				//brakeFRMesh.position=new Vector3D(car.getRigidBody().position.x, car.getWheelInfo(0).worldPosition.y / 100 + car.getRigidBody().y, car.getRigidBody().position.z);
				positionBrake(brakeFRMesh);
				//brakeRLMesh.position=new Vector3D(car.getRigidBody().position.x, car.getWheelInfo(3).worldPosition.y / 100 + car.getRigidBody().y, car.getRigidBody().position.z);
				positionBrake(brakeRLMesh);
				//brakeRRMesh.position=new Vector3D(car.getRigidBody().position.x, car.getWheelInfo(2).worldPosition.y / 100 + car.getRigidBody().y, car.getRigidBody().position.z);
				positionBrake(brakeRRMesh);

				characterFollowController.update();
			}
			_view.render();
		}

		private function positionBrake(brakeMesh:Mesh):void
		{
			brakeMesh.position=car.getRigidBody().position;
			brakeMesh.position.y-=20;
			brakeMesh.rotationX=car.getRigidBody().rotationX;
			brakeMesh.rotationY=car.getRigidBody().rotationY;
			brakeMesh.rotationZ=car.getRigidBody().rotationZ;
		}

		private function positionBodyPart(mesh:Mesh):void
		{
			mesh.position=car.getRigidBody().position;
			mesh.rotationX=car.getRigidBody().rotationX;
			mesh.rotationY=car.getRigidBody().rotationY;
			mesh.rotationZ=car.getRigidBody().rotationZ;
		}


		private function createCones(mesh:Mesh, material:MaterialBase, body:AWPRigidBody):void
		{
			// create rigidbody shapes
			var boxShape:AWPBoxShape=new AWPBoxShape(200, 200, 200);
			var cylinderShape:AWPCylinderShape=new AWPCylinderShape(100, 200);
			var coneShape:AWPConeShape=new AWPConeShape(100, 200);
			for (var i:int=0; i < 12; i++)
			{
				// create boxes
				mesh=new Mesh(new CubeGeometry(200, 200, 200), material);
				_view.scene.addChild(mesh);
				body=new AWPRigidBody(boxShape, mesh, 1);
				body.position=new Vector3D(-5000 + 50000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create cylinders
				mesh=new Mesh(new CylinderGeometry(100, 100, 200), material);
				_view.scene.addChild(mesh);
				body=new AWPRigidBody(cylinderShape, mesh, 1);
				body.position=new Vector3D(-5000 + 50000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);

				// create the Cones
				mesh=new Mesh(new ConeGeometry(100, 200), material);
				_view.scene.addChild(mesh);
				body=new AWPRigidBody(coneShape, mesh, 1);
				body.position=new Vector3D(-5000 + 50000 * Math.random(), 1000 + 1000 * Math.random(), -5000 + 10000 * Math.random());
				physicsWorld.addRigidBody(body);
			}
		}
	}
}
