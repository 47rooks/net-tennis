package player;

import flixel.FlxG;
import haxe.io.BytesBuffer;
import utils.Globals.G;

enum PlayerType {
	USER;
	AI;
	NETWORK_PLAYER;
}

class Player {
	public var id(get, null):Int;
	public var type(get, null):PlayerType;
	public var paddle(default, default):Paddle;
	public var myServe(null, set):Bool;

	public function new(id:Int, type:PlayerType) {
		this.id = id;
		this.type = type;
	}

	function get_type():PlayerType {
		return type;
	}

	function get_id():Int {
		return id;
	}

	/**
	 * Get the latest inputs from the player.
	 * @return Null<PlayerInputs>
	 */
	public function getInput():Null<PlayerInputs> {
		// trace('getting Player.getInput (${id})');
		var inp = new PlayerInputs();
		inp.framenumber = G.gameState.currentFrame;

		// Keyboard input
		if (FlxG.keys.pressed.W) {
			inp.up = true;
		}
		if (FlxG.keys.pressed.S) {
			inp.down = true;
		}
		if (FlxG.keys.justReleased.T && myServe) {
			inp.serve = true;
			myServe = false;
		}
		// Dual player on one keyboard - comment for now
		// if (FlxG.keys.pressed.O) {
		// 	rightPaddleMove(0, -200 * elapsed);
		// }
		// if (FlxG.keys.pressed.K) {
		// 	rightPaddleMove(0, 200 * elapsed);
		// }
		if (G.gameState.connection != null) {
			trace('Player send');
			sendInputToPeer(inp);
		}
		return inp;
	}

	function sendInputToPeer(inp:PlayerInputs):Void {
		// trace('_lastFrameSent=${_lastFrameSent}, G.gameState.currentFrame=${G.gameState.currentFrame}');
		if (G.gameState.lastFrameSent == null || G.gameState.lastFrameSent < G.gameState.currentFrame) {
			var data = new BytesBuffer();
			data.addInt32(G.gameState.currentFrame);
			data.addByte(inp.up ? 1 : 0);
			data.addByte(inp.down ? 1 : 0);
			data.addByte(inp.serve ? 1 : 0);

			// trace('Sending frame ${G.gameState.currentFrame}');
			G.gameState.connection.send(data.getBytes());
			G.gameState.lastFrameSent = G.gameState.currentFrame;
		}
	}

	function set_myServe(value:Bool):Bool {
		return myServe = value;
	}

	/**
	 * Notify the player the rally is over.
	 * 
	 * Do nothing by default. Subclasses needing special handling must
	 * override this method.
	 */
	public function rallyOver():Void {}

	/**
	 * Notify the player that the other player played the ball.
	 * 
	 * Do nothing by default. Subclasses needing special handling must
	 * override this method.
	 */
	public function opponentPlayed():Void {}
}
