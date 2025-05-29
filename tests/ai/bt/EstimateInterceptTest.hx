package ai.bt;

import flixel.math.FlxPoint;
import utest.Assert;
import bitdecay.behavior.tree.context.BTContext;
import utest.Test;

class EstimateInterceptTest extends Test {
	var _btCtx:BTContext;

	function setup():Void {
		_btCtx = new BTContext();
	}

	function testHorizontalVel() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, 0.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(180.0, loc.y);
	}

	function testSlightDownVel() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, 5.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(210.0, loc.y);
	}

	function testSlightUpVel() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, -12.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(108.0, loc.y);
	}

	function testTopBounce1() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, -60.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(180.0, loc.y);
	}

	function testTopBounce2() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, -150.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(0.0, loc.y);
	}

	function testBottomBounce1() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, 60.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(180.0, loc.y);
	}

	function testBottomBounce2() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(100.0, 120.0));
		_btCtx.set("ballPosition", FlxPoint.get(20.0, 180.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(180.0, loc.y);
	}

	function testServe() {
		// Setup
		var node = new EstimateIntercept();
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", 360.0);
		_btCtx.set("ballVelocity", FlxPoint.get(0.0, 0.0));
		_btCtx.set("ballPosition", FlxPoint.get(315.0, 0.0));
		node.init(_btCtx);

		// Test
		node.process(0.016);

		// Verification
		var loc:FlxPoint = _btCtx.get("targetLocation");
		Assert.notNull(_btCtx);
		Assert.floatEquals(620, loc.x);
		Assert.floatEquals(180.0, loc.y);
	}
}
