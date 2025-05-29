package ai.bt;

import flixel.math.FlxPoint;

class MoveToRestLocation extends MoveToLocation {
	function getTargetLocation():FlxPoint {
		return cast ctx.get("restPoint");
	}
}
