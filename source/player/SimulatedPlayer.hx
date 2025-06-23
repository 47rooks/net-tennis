package player;

import ai.bt.EstimateIntercept;
import ai.bt.MoveToInterceptLocation;
import ai.bt.MoveToRestLocation;
import bitdecay.behavior.tree.BT;
import bitdecay.behavior.tree.Node;
import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.composite.Fallback;
import bitdecay.behavior.tree.composite.Sequence;
import bitdecay.behavior.tree.context.BTContext;
import bitdecay.behavior.tree.leaf.Condition;
import bitdecay.behavior.tree.leaf.SetVariable;
import bitdecay.behavior.tree.leaf.StatusAction;
import flixel.FlxG;
import flixel.math.FlxPoint;
import utils.Globals.G;

/**
 * An AI Tennis player.
 * 
 * Currently only ever player 2.
 */
class SimulatedPlayer extends Player {
	public var _ball:Ball; // FIXME should come through the context

	var _btCtx:BTContext;
	var _bt:Node;

	public function new(id:Int) {
		super(id, AI);
		myServe = false;
		// init(); FIXME - deferring initialization until first use
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
            		CONST(FlxPoint.get(paddle.x,
            			               (FlxG.height - paddle.height) / 2.0)));
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
			var inp = new PlayerInputs();
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
		_btCtx.set("paddleLocation", paddle.getPosition());
	}

	/**
	 * Get the latest inputs from the AI player.
	 * @return Null<PlayerInputs>
	 */
	override public function getInput():Null<PlayerInputs> {
		// trace('getting SimulatedPlayer.getInput (${id})');
		if (_btCtx == null) {
			init();
		}
		_btCtx.set("paddleLocation", paddle.getPosition());
		_bt.process(0.016); // Intentionally ignore result
		var inp = _btCtx.get("myInputs");
		_btCtx.remove("myInputs");
		if (inp == null) {
			inp = new PlayerInputs();
		}
		inp.framenumber = G.gameState.currentFrame;
		if (G.gameState.connection != null) {
			trace('SimulatedPlayer send');
			sendInputToPeer(inp);
		}
		return inp;
	}

	/**
	 * Notify the AI player the rally is over.
	 */
	override public function rallyOver():Void {
		setupCtx();
	}

	/**
	 * Notify the AI player that the other player played the ball.
	 */
	override public function opponentPlayed():Void {
		_btCtx.remove("interceptPoint");
		setupCtx();
	}
}
