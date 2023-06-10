package;

import kha.math.FastMatrix4;
import kha.Scheduler;
import kha.System;
import kha.Framebuffer;
import kha.Assets;

class Scene {
	public var model:Model;
	public var proj:FastMatrix4;
	public var modelMatrix:FastMatrix4;

	public function new() {
		// once the assets are loaded, we let kha call that function
		Assets.loadEverything(loadEverything);
	}

	public function loadEverything() {
		model = new Model("backpack.gltf2", "backpack.bin");

		proj = FastMatrix4.perspectiveProjection(45.0, 4.0 / 3.0, 0.1, 100.0);

		modelMatrix = FastMatrix4.identity();
		modelMatrix = FastMatrix4.translation(0.0, 0.0, 0.0);
		modelMatrix = FastMatrix4.scale(1.0, 1.0, 1.0);

		System.notifyOnFrames(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
		// Add mouse and keyboard listeners
		kha.input.Mouse.get().notify(Camera.onMouseDown, Camera.onMouseUp, Camera.onMouseMove, null);
		kha.input.Keyboard.get().notify(Camera.onKeyDown, Camera.onKeyUp);
	}

	public function update() {
		Camera.update();
	}

	public function render(frames:Array<Framebuffer>) {
		// A graphics object which lets us perform 3D operations
		var g = frames[0].g4;

		// Begin rendering
		g.begin();

		// Clear screen
		g.clear(Color.fromFloats(0.2, 0.1, 0.0), 1.0);

		model.draw(g, proj, modelMatrix, Camera.view);

		// End rendering
		g.end();
	}
}
