package ai.bt;

import flixel.math.FlxPoint;

class MoveToInterceptLocation extends MoveToLocation {
	function getTargetLocation():FlxPoint {
		return cast ctx.get("interceptPoint");
	}
}
