package ai.bt;

import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.leaf.LeafNode;
import flixel.math.FlxPoint;
import player.PlayerInputs;

abstract class MoveToLocation extends LeafNode {
	public function new() {}

	abstract function getTargetLocation():FlxPoint;

	override public function process(delta:Float):NodeStatus {
		var targetLocation:Null<FlxPoint> = getTargetLocation();
		if (targetLocation == null) {
			return FAIL;
		}
		var pos:Null<FlxPoint> = ctx.get("paddleLocation");
		if (pos == null) {
			return FAIL;
		}
		var t = Std.int(targetLocation.y);
		var p = Std.int(pos.y);
		if (t == p) {
			ctx.set("myInputs", new PlayerInputs());
			return SUCCESS;
		}
		var inp = new PlayerInputs();
		if (t > p) {
			inp.down = true;
		} else if (t < p) {
			inp.up = true;
		}
		ctx.set("myInputs", inp);
		return RUNNING;
	}
}
