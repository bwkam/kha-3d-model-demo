package;

import kha.input.Mouse;
import kha.Color;
import zui.Ext;
import zui.Id;
import zui.Zui;
import kha.math.FastVector3;
import haxe.Timer;
import kha.math.FastMatrix4;
import kha.Scheduler;
import kha.System;
import kha.Framebuffer;
import kha.Assets;

class Scene {
	public var model:Model;
	public var proj:FastMatrix4;
	public var modelMatrix:FastMatrix4;
	public var ui:Zui;

	public var pointLightAmbient:Handle;
	public var pointLightDiffuse:Handle;
	public var pointLightSpecular:Handle;
	public var cutOff:Handle;
	public var outerCutOff:Handle;
	public var pointLightColor:Handle;
	public var pointLightColorV:Color;

	public var lightPosition:FastVector3;

	public function new() {
		// once the assets are loaded, we let kha call that function
		Assets.loadEverything(loadEverything);
	}

	public function loadEverything() {
		model = new Model("backpack.gltf2", "backpack.bin");

		proj = FastMatrix4.perspectiveProjection(45.0, 4.0 / 3.0, 0.1, 100.0);
		lightPosition = new FastVector3();

		modelMatrix = FastMatrix4.identity();
		modelMatrix = FastMatrix4.translation(0.0, 0.0, 0.0);
		modelMatrix = FastMatrix4.scale(1.0, 1.0, 1.0);

		ui = new Zui({
			font: Assets.fonts.DroidSans,
			color_wheel: Assets.images.color_wheel,
			black_white_gradient: Assets.images.black_white_gradient
		});

		pointLightAmbient = Id.handle();
		pointLightDiffuse = Id.handle();
		pointLightSpecular = Id.handle();
		cutOff = Id.handle();
		outerCutOff = Id.handle();
		pointLightColor = Id.handle();
		pointLightColorV = Red;

		System.notifyOnFrames(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		// Add mouse and keyboard listeners
		kha.input.Mouse.get().notify(Camera.onMouseDown, Camera.onMouseUp, Camera.onMouseMove, null);
		kha.input.Mouse.get().notify(null, null, (x, y, dx, dy) -> {
			lightPosition.x = x / 640.0;
			lightPosition.y = y / -480.0;
			lightPosition.z = 0.0;
			trace(lightPosition.x, lightPosition.y);
		}, null);
		kha.input.Keyboard.get().notify(Camera.onKeyDown, Camera.onKeyUp);
	}

	public function update() {
		Camera.update();
		var r = 10;
		var posX = Math.cos(Timer.stamp() * r);
		var posZ = Math.sin(Timer.stamp() * r);
		// modelMatrix =
	}

	public function render(frames:Array<Framebuffer>) {
		// A graphics object which lets us perform 3D operations
		var g = frames[0].g4;
		var g2 = frames[0].g2;

		// Begin rendering
		g.begin();

		// Clear screen
		g.clear(Color.fromFloats(0.0, 0.0, 0.0), 1.0);

		model.draw(g, proj, modelMatrix, Camera.view, {
			constant: 1.0,
			linear: 0.09,
			quadratic: 0.032,
			shininess: 32.0,
			ambient: new FastVector3(pointLightColorV.R * pointLightAmbient.value, pointLightColorV.G * pointLightAmbient.value,
				pointLightColorV.B * pointLightAmbient.value),
			diffuse: new FastVector3(pointLightColorV.R * pointLightDiffuse.value, pointLightColorV.G * pointLightDiffuse.value,
				pointLightColorV.B * pointLightDiffuse.value),
			specular: new FastVector3(pointLightColorV.R * pointLightSpecular.value, pointLightColorV.G * pointLightSpecular.value,
				pointLightColorV.B * pointLightSpecular.value),
			position: lightPosition,
			cutOff: Math.cos(cutOff.value * Math.PI / 180),
			outerCutOff: Math.cos(outerCutOff.value * Math.PI / 180),
			direction: new FastVector3(0.0, 0.0, -1.0),
		});

		// End rendering
		g.end();

		ui.begin(g2);
		// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.handle(), 10, 10, 240, 600, true)) {
			if (ui.panel(Id.handle({selected: true}), "Light")) {
				ui.indent();
				if (ui.panel(Id.handle({selected: false}), "Pointlight")) {
					ui.indent();
					ui.slider(pointLightAmbient, "ambient", 0, 5, true);
					ui.slider(pointLightDiffuse, "diffuse", 0, 5, true);
					ui.slider(pointLightSpecular, "specular", 0, 5, true);
					ui.slider(cutOff, "cutOff", 0, 90, true);
					ui.slider(outerCutOff, "outerCutOff", 0, 90, true);
					pointLightColorV = Ext.colorWheel(ui, pointLightColor);
					ui.unindent();
				}

				ui.separator();
				ui.unindent();
			}
		}

		ui.end();
	}
}
