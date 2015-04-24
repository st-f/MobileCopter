package
{
	import Model.CellShadingPhysicsTest;
	import Model.City;
	import Model.ExhaustSmoke;
import Model.Fire;
import Model.Skybox;

	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.debug.Trident;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.lights.PointLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.SkyBox;

	import awayphysics.dynamics.AWPDynamicsWorld;

	import com.bit101.components.NumericStepper;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StageOrientationEvent;
	import flash.events.TransformGestureEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;

	import mx.events.FlexEvent;

	//[SWF(width='1280', height='800', backgroundColor='#000000', frameRate='30')]
	[SWF(width='960', height='540', backgroundColor='#000000', frameRate='60')]
	public class MobileCopter extends Sprite
	{
		public function MobileCopter()
		{
			super();
			creationCompleteHandler();
		}

		private var scene:Scene3D;
		private var camera:Camera3D;
		public var view:View3D;
		private var awayStats:AwayStats;
		//private var axes:WireframeAxesGrid;

		private var cameraController:HoverController;
		private var displayMesh:Mesh;
		private var modelContainer:ObjectContainer3D;

		private var city:City;

		private var physicsWorld:AWPDynamicsWorld;
		private var physicsTest:CellShadingPhysicsTest;
		private var _timeStep:Number=1.0 / 60;

		private var pointLight:PointLight;
		private var pointLight2:PointLight;
		private var lightPicker:StaticLightPicker;

		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;

		/*private var f:FileReference;
		private var filter:Array;*/

		private var tiltIncrement:Number=0;
		private var panIncrement:Number=0;
		private var distanceIncrement:Number=0;
		public const tiltSpeed:Number=2;
		public const panSpeed:Number=2;
		public const distanceSpeed:Number=8;
		private static const MODEL_SCALE:Number=5;

		private var zoom:Number=0;
		private var rotateX:Number=-1;
		private var rotateY:Number=18;
		private var rotateZ:Number=-1;

		private var secondaryRotorMesh:Mesh;
		private var mainRotorMesh:Mesh;
		private var windowsMesh:Mesh;
		private var rotorSpeed:Number=-16;
		private var rotorSpeedNumstep:NumericStepper;

		private var pivotXvalue:int=0;
		private var pivotYvalue:int=0;
		private var pivotZvalue:int=-105;
		private var pivotXnumstep:NumericStepper;
		private var pivotYnumstep:NumericStepper;
		private var pivotZnumstep:NumericStepper;

		private var cellShadingMaterial:ColorMaterial;
		private var windowsMaterial:ColorMaterial=new ColorMaterial(0xCCCCCC, 0.3);

		private var move:Boolean=false;

		protected function creationCompleteHandler(event:FlexEvent=null):void
		{
			initScene();
			//initPhysics();
			//addUI();
			initFile();
			stage.align=StageAlign.TOP_LEFT;
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChanged);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			view.addEventListener(TransformGestureEvent.GESTURE_ZOOM, handleGestureZoom);
			this.addEventListener(Event.RESIZE, onResize);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function initScene():void
		{
			view=new View3D();
			view.backgroundColor=0x999999;
			view.antiAlias=4;
			view.forceMouseMove=true;
			scene=view.scene;
			camera=view.camera;
			camera.lens.far=30000;

			this.addChild(view);
			cameraController=new HoverController(camera, null, 45, 30, 650);
			/*var axes:WireframeAxesGrid = new WireframeAxesGrid(50, 1000, 1, 0xDDDDDD, 0xDDDDDD, 0xDDDDDD);
			scene.addChild(axes);*/
			var trident:Trident=new Trident();
			scene.addChild(trident);

			awayStats=new AwayStats(view);
			this.addChild(awayStats);
			createLights();
			createSmoke();
			createPanorama();
			createMaterials();
			createTerrain();
		}


		private function createLights():void
		{
			pointLight=new PointLight();
			pointLight.diffuse=.5;
			pointLight.ambient=0.0;

            pointLight.rotationZ = 40;
			scene.addChild(pointLight);
			pointLight2=new PointLight();
			pointLight2.diffuse=.5;
			pointLight.ambient=0.0;
			//scene.addChild(pointLight2);
			// In version 4, you'll need a lightpicker. Materials must then be registered with it (see initObject)
			lightPicker=new StaticLightPicker([pointLight, pointLight2]);
			//lightPicker=new StaticLightPicker([pointLight]);
			pointLight.position=camera.position;
			pointLight.x=-1200;
			pointLight.y=5500;
			pointLight2.position=camera.position;
			pointLight2.x=-1000;
			pointLight2.y=7500;
		}

		private function createPanorama():void
		{
			var skybox:Skybox=new Skybox(false);
			scene.addChild(new SkyBox(skybox.bitmapCubeTexture));
		}

		private function createSmoke():void
		{
			/*var fire:Fire = new Fire();
			fire.rotationX = 90;
			fire.y = 30;
			fire.z = 80;
			view.scene.addChild(fire);     */
			var smoke:ExhaustSmoke=new ExhaustSmoke();
			smoke.rotationX=90;
			smoke.y=30;
			smoke.z=80;
			view.scene.addChild(smoke);
		}

		private function createMaterials():void
		{
			cellShadingMaterial=new ColorMaterial(0xAAAAAA, 1);
			//ultra slow
			//cellShadingMaterial.diffuseMethod=new CelDiffuseMethod();
			//cellShadingMaterial.specularMethod=new CelSpecularMethod(2);
			//cellShadingMaterial.addMethod(new OutlineMethod(0x111111, 0.1, true, true));
			cellShadingMaterial.lightPicker=lightPicker;
		}

		private function createTerrain():void
		{
			/*physicsTest=new CellShadingPhysicsTest(view.scene, lightPicker, physicsWorld);
			physicsTest.createTerrain();*/
			trace("createTerrain");
			city=new City(view.scene, lightPicker);
			city.createCity();
		}

		private function onEnterFrame(event:Event):void
		{
			if (modelContainer)
			{
				if (rotateX != -1)
					cleanRotate(modelContainer, "x", rotateX);
				if (rotateY != -1)
				{
					cleanRotate(mainRotorMesh, "y", rotateY);
					cleanRotate(secondaryRotorMesh, "x", rotateY * 2);
				}
				if (rotateZ != -1)
					cleanRotate(modelContainer, "z", rotateZ);

				if (move)
				{
					cameraController.panAngle=0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
					cameraController.tiltAngle=0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
				}
				cameraController.panAngle+=panIncrement;
				cameraController.tiltAngle+=tiltIncrement;
				cameraController.distance+=distanceIncrement;
				/*if (physicsWorld)
				physicsWorld.step(_timeStep, 1, _timeStep);*/
			}
			view.render();
		}

		private function handleGestureZoom(event:TransformGestureEvent):void
		{
			cameraController.distance+=(1 - event.scaleX) * 500;
		}

		private function onOrientationChanged(event:StageOrientationEvent):void
		{
			onResize();
		}

		private function initPhysics():void
		{
			physicsWorld=AWPDynamicsWorld.getInstance();
		}

		private function initFile():void
		{
			Parsers.enableAllBundled();
			var _loader:Loader3D=new Loader3D();
			_loader.load(new URLRequest('assets/mh6.obj'));
            _loader.addEventListener(LoaderEvent.LOAD_ERROR, onModelResourceError);
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onModelResourceComplete);
		}

		private function onModelResourceError(event:LoaderEvent):void
		{
            trace("onModelResourceError");
        }

		private function onModelResourceComplete(event:LoaderEvent):void
		{
			modelContainer=ObjectContainer3D(event.target);
			modelContainer.y-=100;
			view.backgroundColor=0x222222;
			view.scene.addChild(modelContainer);
			for (var i:int=0; i < modelContainer.numChildren; i++)
			{
				displayMesh=Mesh(modelContainer.getChildAt(i));
				trace("children: " + displayMesh.name);
				if (i == 0)
				{
					secondaryRotorMesh=displayMesh;
					secondaryRotorMesh.pivotPoint=new Vector3D(0, 177, 320);
				}
				if (i == 2)
				{
					mainRotorMesh=displayMesh;
					mainRotorMesh.pivotPoint=new Vector3D(pivotXvalue, pivotYvalue, pivotZvalue);
				}
				if (i == 3)
				{
					windowsMesh=displayMesh;
					windowsMesh.material=windowsMaterial;
				}
				else
				{
					displayMesh.material=cellShadingMaterial;
				}
				displayMesh.geometry.scale(MODEL_SCALE);
			}
			trace("model ready.");
		}

		private function onMouseDown(event:MouseEvent):void
		{
			move=true;
			lastPanAngle=cameraController.panAngle;
			lastTiltAngle=cameraController.tiltAngle;
			lastMouseX=stage.mouseX;
			lastMouseY=stage.mouseY;
			//stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		private function onMouseUp(event:MouseEvent):void
		{
			move=false;
			//stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		public function removeListeners():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(Event.RESIZE, onResize);
			//	removeEventListener(MouseEvent.MOUSE_WHEEL, handleMouseWheel);
		}

		private function addUI():void
		{
			pivotXnumstep=new NumericStepper(this, 10, 10, handlePivotXnumstepChange);
			addChild(pivotXnumstep);
			pivotXnumstep.value=pivotXvalue;
			pivotYnumstep=new NumericStepper(this, 100, 10, handlePivotXnumstepChange);
			addChild(pivotYnumstep);
			pivotYnumstep.value=pivotYvalue;
			pivotZnumstep=new NumericStepper(this, 190, 10, handlePivotXnumstepChange);
			addChild(pivotZnumstep);
			pivotZnumstep.value=pivotZvalue;
			rotorSpeedNumstep=new NumericStepper(this, 300, 10, handlePivotXnumstepChange);
			addChild(rotorSpeedNumstep);
			rotorSpeedNumstep.value=rotorSpeed;
		}

		private function handlePivotXnumstepChange(event:Event):void
		{
			pivotXvalue=pivotXnumstep.value;
			pivotYvalue=pivotYnumstep.value;
			pivotZvalue=pivotZnumstep.value;
			rotorSpeed=rotorSpeedNumstep.value;
			rotateY=rotorSpeed;
			//var blur:BlurFilter3D = new BlurFilter3D(10,10);
			//var dop:DepthOfFieldFilter3D=new DepthOfFieldFilter3D(10, 10, 3);
			//blur.
			//view.filters3d = [dop];
			modelContainer.getChildAt(2).pivotPoint=new Vector3D(pivotXvalue, pivotYvalue, pivotZvalue);
			trace("set pivot: " + event + " > " + displayMesh.pivotPoint);
		}

		private var temprot:int;

		private function cleanRotate(obj:ObjectContainer3D, axis:String, rotation:Number):void
		{
			temprot=0;
			switch (axis)
			{
				case "x":
				{
					temprot=obj.rotationX;
					break;
				}
				case "y":
				{
					temprot=obj.rotationY;
					break;
				}
				case "z":
				{
					temprot=obj.rotationZ;
					break;
				}
				default:
				{
					break;
				}
			}
			if (temprot <= 360 - rotation)
			{
				temprot+=rotation;
			}
			else
			{
				temprot=0;
			}
			//temprot+=rotation;
			switch (axis)
			{
				case "x":
				{
					obj.rotationX=temprot;
					break;
				}
				case "y":
				{
					obj.rotationY=temprot;
					break;
				}
				case "z":
				{
					obj.rotationZ=temprot;
					break;
				}
				default:
				{
					break;
				}
			}
		}

		/*private function handleMouseWheel(event:MouseEvent):void
		{
			trace(event.delta);
			if (event.delta > 0)
			{
				camera.moveForward(event.delta);
			}
			else
			{
				camera.moveBackward(Math.abs(event.delta));
			}
		}*/

		public function onResize(event:Event=null):void
		{
			view.width=stage.stageWidth;
			view.height=stage.stageHeight;
			trace("resize: " + stage.stageWidth);
		}


		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
					tiltIncrement=tiltSpeed;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement=-tiltSpeed;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					panIncrement=panSpeed;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement=-panSpeed;
					break;
				case Keyboard.Z:
					distanceIncrement=distanceSpeed;
					break;
				case Keyboard.X:
					distanceIncrement=-distanceSpeed;
					break;
				case Keyboard.T:
					physicsTest.shootSphere();
					break;
			}
		}

		/**
		 * Key up listener for camera control
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement=0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement=0;
					break;
				case Keyboard.Z:
				case Keyboard.X:
					distanceIncrement=0;
					break;
				case Keyboard.F:
					if (stage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE)
					{
						stage.displayState=StageDisplayState.FULL_SCREEN_INTERACTIVE;
					}
					else
					{
						stage.displayState=StageDisplayState.NORMAL;
					}
					break;
				case Keyboard.I:
					tiltIncrement=5;
					break;
				case Keyboard.O:
					tiltIncrement=1;
					break;
				case Keyboard.P:
					tiltIncrement=0;
					break;
				case Keyboard.K:
					panIncrement=10;
					break;
				case Keyboard.L:
					panIncrement=1;
					break;
				case Keyboard.M:
					panIncrement=0;
					break;
				case Keyboard.J:
					panIncrement=0;
					break;
				case Keyboard.G:
					physicsTest.shake();
					break;
			}
		}
	}
}
