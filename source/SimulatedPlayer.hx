package;

import ai.bt.MoveToRestLocation;
import ai.bt.MoveToInterceptLocation;
import TennisState.PeerInputs;
import flixel.math.FlxPoint;
import flixel.FlxG;
import ai.bt.EstimateIntercept;
import bitdecay.behavior.tree.leaf.Condition;
import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.BT;
import bitdecay.behavior.tree.leaf.StatusAction;
import bitdecay.behavior.tree.leaf.SetVariable;
import bitdecay.behavior.tree.composite.Sequence;
import bitdecay.behavior.tree.Node;
import bitdecay.behavior.tree.context.BTContext;
import bitdecay.behavior.tree.composite.Fallback;

/**
 * An AI Tennis player.
 * 
 * Currently only ever player 2.
 */
class SimulatedPlayer {
	var _ball:Ball;
	var _paddle:Paddle;
	var _btCtx:BTContext;
	var _bt:Node;

	public var myServe:Bool;

	public function new(ball:Ball, paddle:Paddle) {
		_ball = ball;
		_paddle = paddle;
		myServe = false;
		init();
	}

	public function init():Void {
		_btCtx = new BTContext();
		// @formatter:off

		var isBallIncoming = new StatusAction(BT.wrapFn(ballIncoming));

		// handle intercepting the incoming ball
		var estimateIntercept = new EstimateIntercept();
		var gotInterceptPoint = new Condition("gotInterceptPoint",
											  VAR_SET("interceptPoint"));
		var getInterceptPoint = new Fallback(IN_ORDER,
											 [gotInterceptPoint,
											  estimateIntercept,
											 ],
											 "getInterceptPoint");

		// Move to rest position
		var isBallOutgoing = new StatusAction(BT.wrapFn(ballOutgoing));
		var setRestPosition = new SetVariable("restPoint",
            		CONST(FlxPoint.get(_paddle.x,
            			               (FlxG.height - _paddle.height) / 2.0)));
									   var moveToInterceptLocation = new MoveToInterceptLocation();
	    var moveToRestLocation = new MoveToRestLocation();

		var moveToRest = new Sequence(IN_ORDER,
									  [ isBallOutgoing,
										setRestPosition,
										moveToRestLocation
									  ],
									  "moveToRest");

		var prepareAndHitBall = new Sequence(IN_ORDER, [
			isBallIncoming,
			getInterceptPoint,
			moveToInterceptLocation,
		], "prepareAndHitBall");

		// Handle serving the ball
		var isBallStationary = new StatusAction(BT.wrapFn(ballStationary));
		var isItMyServe = new StatusAction(BT.wrapFn((_, _) -> {
			return myServe ? SUCCESS : FAIL;
		}));
		var serveBall = new StatusAction(BT.wrapFn((_, _) -> {
			var inp = new PeerInputs();
			inp.serve = true;
			_btCtx.set("myInputs", inp);
			return SUCCESS;
		}));

		var serve = new Sequence(IN_ORDER,
								 [ isBallStationary,
								  isItMyServe,
								  serveBall,
								 ],
								 "serve")	;

		// Play
		_bt = new Fallback(IN_ORDER, [
						   prepareAndHitBall,
						   moveToRest,
						   serve,

						   ]);

		// @formatter:on
		_bt.init(_btCtx);
		setupCtx();
	}

	/**
	 * Check if the ball is coming towards me.
	 * 
	 * @param ctx BTree context
	 * @param delta elapsed time since last check
	 * @return NodeStatus
	 */
	function ballIncoming(ctx:BTContext, delta:Float):NodeStatus {
		// Simplistically it is my turn if the ball is increasing X, heading
		// toward me.
		if (_ball.last.x < _ball.x && _ball.velocity.lengthSquared != 0) {
			_btCtx.set("ballVelocity", _ball.velocity);
			return SUCCESS;
		}
		return FAIL;
	}

	/**
	 * Check if the ball is going away from me.
	 * 
	 * @param ctx BTree context
	 * @param delta elapsed time since last check
	 * @return NodeStatus
	 */
	function ballOutgoing(ctx:BTContext, delta:Float):NodeStatus {
		// Simplistically it is my turn if the ball is decreasing X, it
		// is heading away.
		if (_ball.last.x > _ball.x && _ball.velocity.lengthSquared != 0) {
			return SUCCESS;
		}
		return FAIL;
	}

	function ballStationary(ctx:BTContext, delta:Float):NodeStatus {
		if (_ball.velocity.x == 0.0) {
			return SUCCESS;
		}
		return FAIL;
	}

	/**
	 * Setup the context for this iteration turn.
	 */
	function setupCtx():Void {
		_btCtx.set("a1", TennisState.LEFT_X);
		_btCtx.set("a2", 620.0);
		_btCtx.set("b1", 0.0);
		_btCtx.set("b2", FlxG.height);
		_btCtx.set("ballVelocity", _ball.velocity);
		_btCtx.set("ballPosition", _ball.getPosition());
		_btCtx.set("paddleLocation", _paddle.getPosition());
	}

	/**
	 * Get the latest inputs from the AI player.
	 * @return Null<PeerInputs>
	 */
	public function getInput():Null<PeerInputs> {
		_btCtx.set("paddleLocation", _paddle.getPosition());
		_bt.process(0.016); // Intentionally ignore result
		var inp = _btCtx.get("myInputs");
		_btCtx.remove("myInputs");
		if (inp == null) {
			inp = new PeerInputs();
		}
		return inp;
	}

	/**
	 * Notify the AI player the rally is over.
	 */
	public function rallyOver():Void {
		setupCtx();
	}

	/**
	 * Notify the AI player that the other player played the ball.
	 */
	public function opponentPlayed():Void {
		_btCtx.remove("interceptPoint");
		setupCtx();
	}
}
