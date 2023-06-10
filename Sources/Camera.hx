import kha.input.KeyCode;
import kha.math.FastMatrix4;
import kha.Scheduler;
import kha.math.FastVector3;

class Camera {
	public static var position:FastVector3 = new FastVector3(0, 0, 5); // Initial position: on +Z
	public static var horizontalAngle = 3.14; // Initial horizontal angle: toward -Z
	public static var verticalAngle = 0.0; // Initial vertical angle: none

	public static var moveForward = false;
	public static var moveBackward = false;
	public static var strafeLeft = false;
	public static var strafeRight = false;
	public static var isMouseDown = false;

	public static var lastTime = 0.0;

	public static var mouseX = 0.0;
	public static var mouseY = 0.0;
	public static var mouseDeltaX = 0.0;
	public static var mouseDeltaY = 0.0;

	public static var speed = 3.0; // 3 units / second
	public static var mouseSpeed = 0.005;

	public static var view:FastMatrix4;
	public static var look:FastVector3;

	public static function update() {
		// Compute time difference between current and last frame
		var deltaTime = Scheduler.time() - lastTime;
		lastTime = Scheduler.time();

		// Compute new orientation
		if (isMouseDown) {
			horizontalAngle += mouseSpeed * mouseDeltaX * -1;
			verticalAngle += mouseSpeed * mouseDeltaY * -1;
		}

		// Direction : Spherical coordinates to Cartesian coordinates conversion
		var direction = new FastVector3(Math.cos(verticalAngle) * Math.sin(horizontalAngle), Math.sin(verticalAngle),
			Math.cos(verticalAngle) * Math.cos(horizontalAngle));

		// Right vector
		var right = new FastVector3(Math.sin(horizontalAngle - 3.14 / 2.0), 0, Math.cos(horizontalAngle - 3.14 / 2.0));

		// Up vector
		var up = right.cross(direction);

		// Movement
		if (moveForward) {
			var v = direction.mult(deltaTime * speed);
			position = position.add(v);
		}
		if (moveBackward) {
			var v = direction.mult(deltaTime * speed * -1);
			position = position.add(v);
		}
		if (strafeRight) {
			var v = right.mult(deltaTime * speed);
			position = position.add(v);
		}
		if (strafeLeft) {
			var v = right.mult(deltaTime * speed * -1);
			position = position.add(v);
		}

		// Look vector
		look = position.add(direction);

		// Camera matrix
		view = FastMatrix4.lookAt(position, // Camera is here
			look, // and looks here : at the same position, plus "direction"
			up // Head is up (set to (0, -1, 0) to look upside-down)
		);

		mouseDeltaX = 0;
		mouseDeltaY = 0;
	}

	public static function onMouseDown(button:Int, x:Int, y:Int) {
		isMouseDown = true;
	}

	public static function onMouseUp(button:Int, x:Int, y:Int) {
		isMouseDown = false;
	}

	public static function onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
		mouseDeltaX = x - mouseX;
		mouseDeltaY = y - mouseY;

		mouseX = x;
		mouseY = y;
	}

	public static function onKeyDown(key:Int) {
		if (key == KeyCode.Up)
			moveForward = true;
		else if (key == KeyCode.Down)
			moveBackward = true;
		else if (key == KeyCode.Left)
			strafeLeft = true;
		else if (key == KeyCode.Right)
			strafeRight = true;
	}

	public static function onKeyUp(key:Int) {
		if (key == KeyCode.Up)
			moveForward = false;
		else if (key == KeyCode.Down)
			moveBackward = false;
		else if (key == KeyCode.Left)
			strafeLeft = false;
		else if (key == KeyCode.Right)
			strafeRight = false;
	}
}
