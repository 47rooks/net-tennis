package ai.bt;

import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.leaf.LeafNode;
import flixel.math.FlxPoint;

class EstimateIntercept extends LeafNode {
	static final TOP_NORMAL = FlxPoint.get(0.0, -1.0);
	static final BOTTOM_NORMAL = FlxPoint.get(0.0, 1.0);

	public function new() {}

	override public function process(delta:Float):NodeStatus {
		// Compute the intercept
		var ballVel:FlxPoint = ctx.get("ballVelocity");
		var ballPos:FlxPoint = ctx.get("ballPosition");
		var a1:Float = ctx.get("a1");
		var a2:Float = ctx.get("a2");
		var b1:Float = ctx.get("b1");
		var b2:Float = ctx.get("b2");

		trace('bv=${ballVel}');
		trace('bp=${ballPos}');
		trace('a1=${a1}, a2=${a2}, b1=${b1}, b2=${b2}');

		var vX:Float = ballVel.x;
		var vY:Float = ballVel.y;
		var p0X:Float = ballPos.x;
		var p0Y:Float = ballPos.y;
		var normal = TOP_NORMAL;

		ctx.remove("interceptPoint");
		var loopCnt = 10;
		while (true && loopCnt-- > 0) {
			// Use parametric form of ball velocity vector and position
			// to compute the wall intercept point. It could be top, bottom
			// or left wall.

			// Compute left wall first
			var t = (a2 - p0X) / vX;
			var py = p0Y + vY * t;
			var px = a2;
			if (py >= 0 && py < b2) {
				// We hit the back wall.
				// Store the intercept in the context
				trace('RIGHT: t=${t}, px=${px}, py=${py}');
				ctx.set("interceptPoint", FlxPoint.get(px, py - 20));
				break;
			}

			// If the ball is going up compute intecept with top, else
			// compute intercept with bottom.

			// Set x value to the current p0X so we move across
			// court.
			px = p0X;
			if (py < p0Y) {
				// Intercept with top
				t = -(p0Y / vY);
				px = p0X - (vX * p0Y) / vY;
				py = 0;
				normal = TOP_NORMAL;
				trace('TOP: ${t}, px=${px}, py=${py}');
				// FIXME add assert that this is not out of bounds ?
			} else {
				// Intecept with bottom
				t = (b2 - p0Y) / vY;
				px = p0X + vX * (b2 - p0Y) / vY;
				py = b2;
				normal = BOTTOM_NORMAL;
				trace('BOTTOM: ${t}, px=${px}, py=${py}');
				// FIXME add assert that this is not out of bounds ?
			}

			// Bounce off wall and create new velocity vector
			p0X = px;
			p0Y = py;
			var oldV = FlxPoint.get(vX, vY);
			var newV = oldV.bounce(normal);
			trace('newV=${newV}');
			vX = newV.x;
			vY = newV.y;
		}

		return SUCCESS;
	}
}
