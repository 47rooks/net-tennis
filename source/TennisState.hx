package;

import player.PlayerInputs;
import player.SimulatedPlayer;
import player.Player;
import utils.GameState;
import utils.Globals;
import haxe.ds.List;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import network.Client;
import network.Server;
import sys.thread.Mutex;
import network.NetworkException;
import network.Listener;
import sys.net.Host;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class TennisState extends FlxState {
	public var _ball:Ball;

	var _leftPaddle:Paddle;
	var _rightPaddle:Paddle;
	var _net:FlxSprite;
	var _leftScore:FlxText;
	var _rightScore:FlxText;

	public static final LEFT_X = 10;

	public final RIGHT_X = FlxG.width - 20;

	final PADDLE_SPEED = 100;

	var _leftPoints = 0;
	var _rightPoints = 0;

	var _ipAddr:Null<String> = null;
	var _port:Null<Int> = null;
	var _server:Bool = false;
	var _listenerHost:Null<Host> = null;
	var _listener:Null<Listener> = null;
	var _listenerError:NetworkException;
	var _listenerErrorMutex:Mutex;

	var _clientNewCount = 0;

	var _player1:Player;
	var _player2:Player;

	var _playerInputs:Null<Array<PlayerInputs>> = null;

	// Game state vars
	var _player:Null<Int>;
	var _playerToServe:Null<Int>;
	var _initialized:Bool = false;
	var _lastFrameSent:Null<Int> = null;

	final NEW = 1;
	final CONNECTED = 2;
	final GLOBALLY_INITIALIZED = 3;
	final OUT_OF_SYNC = 4;

	var _messagingState:Null<Int> = null;

	public function new(?ipAddr:Null<String>, ?port:Null<Int>, ?server = false, player1:Player, player2:Player) {
		_ipAddr = ipAddr;
		_port = port;
		_server = server;
		_player1 = player1;
		_player2 = player2;

		if (_ipAddr != null) {
			_listenerHost = new Host(StringTools.trim(_ipAddr));
		}

		if (_server) {
			_player = GameState.PLAYER_ONE;
		} else {
			_player = GameState.PLAYER_TWO;
		}
		_messagingState = NEW;

		super();

		FlxG.autoPause = false;

		_playerInputs = new Array<PlayerInputs>();
	}

	override public function create() {
		super.create();

		// Create the ball and paddles
		_ball = new Ball();
		_ball.makeGraphic(10, 10, FlxColor.RED);
		_ball.screenCenter();
		_ball.elasticity = 1.0;

		_leftPaddle = new Paddle(LEFT_X, FlxG.height / 2.0 - 20);
		_leftPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_leftPaddle.immovable = true;

		_rightPaddle = new Paddle(RIGHT_X, FlxG.height / 2.0 - 20);
		_rightPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_rightPaddle.immovable = true;

		// Assign paddles to players
		_player1.paddle = _leftPaddle;
		_player2.paddle = _rightPaddle;
		// FIXME This is a hack to get the ball into the AI player.
		//       The ball should go via a context push.
		if (_player1.type == AI) {
			cast(_player1, SimulatedPlayer)._ball = _ball;
		}
		if (_player2.type == AI) {
			cast(_player2, SimulatedPlayer)._ball = _ball;
		}
		// -----

		_net = new FlxSprite();

		_net.loadGraphic('assets/images/Net.png');
		_net.screenCenter();
		_net.y = 0;

		_leftScore = new FlxText(FlxG.width / 4.0, 10, 20, '${_leftPoints}', 20);
		_leftScore.textField.antiAliasType = ADVANCED;
		_leftScore.textField.sharpness = 400;

		_rightScore = new FlxText(3 * FlxG.width / 4.0, 10, 20, '${_rightPoints}', 20);
		_rightScore.textField.antiAliasType = ADVANCED;
		_rightScore.textField.sharpness = 400;

		add(_leftPaddle);
		add(_rightPaddle);
		add(_ball);
		add(_net);
		add(_leftScore);
		add(_rightScore);
	}

	function startListener():Void {
		if (_server && _listenerHost != null && _port != null) {
			_listener = new Listener(_listenerHost, _port, newClientHandler, listenerErrorHandler);
		}
	}

	function startClient():Void {
		if (!_server && G.gameState.connection == null && _listenerHost != null && _port != null) {
			trace('trying to connect');
			// Create a network object
			try {
				var client = new Client();
				_clientNewCount++;
				client.connect(_listenerHost, _port);
				G.gameState.connection = client;
				trace('connected');

				initializeGameState();
			} catch (ne:NetworkException) {
				handleException(ne);
			}
		}
	}

	public function listenerErrorHandler(ne:NetworkException) {
		_listenerErrorMutex.acquire();
		_listenerError = ne;
		_listenerErrorMutex.release();
	}

	function handleException(ne:NetworkException):Void {
		switch (ne.error) {
			case EOF:
				// Server went away - throw away Client object
				G.gameState.connection.close();
				G.gameState.connection = null;
			case INVALID_SOCKET_HANDLE:
				trace('socket no good. ${_clientNewCount}');
				G.gameState.connection.close();
				G.gameState.connection = null;
			default:
				// FIXME Client recovery
				trace('Got exception: ${ne.error}');
				G.gameState.connection.close();
				G.gameState.connection = null;
		}
	}

	/**
	 * Process an newly arrived client.
	 *
	 * This is MT safe as it inserts into a Deque which will be reaped later  
	 * by the main thread.
	**/
	public function newClientHandler(client:Server) {
		if (G.gameState.connection != null) {
			// Already connected - reject the new connection
			client.close();
			return;
		}
		G.gameState.connection = client;
		trace('${Timer.stamp()}:client connected');

		// FIXME - this needs to be handled in the server thread at the
		//         right place. We are currently skipping frame #0
		// initializeGameState();
		// Send initial setup message
		// FIXME - not quite yet but very soon
	}

	function initializeGameState():Void {
		_playerToServe = GameState.PLAYER_ONE;
		_player1.myServe = true;
		G.gameState.currentFrame = 0;

		_initialized = true;
	}

	public function leftPaddleMove(x:Float, y:Float):Void {
		_leftPaddle.x += x;
		_leftPaddle.y += y;
		if (_leftPaddle.y < 0) {
			_leftPaddle.y = 0;
		}
		if (_leftPaddle.y > FlxG.height - _leftPaddle.height) {
			_leftPaddle.y = FlxG.height - _leftPaddle.height;
		}
	}

	public function rightPaddleMove(x:Float, y:Float):Void {
		_rightPaddle.x += x;
		_rightPaddle.y += y;
		if (_rightPaddle.y < 0) {
			_rightPaddle.y = 0;
		}
		if (_rightPaddle.y > FlxG.height - _rightPaddle.height) {
			_rightPaddle.y = FlxG.height - _rightPaddle.height;
		}
	}

	public function serve(x:Float, y:Float, speed:Float, degrees:Float):Void {
		_ball.x = x;
		_ball.y = y;
		_ball.velocity.setPolarDegrees(speed, degrees);

		// FIXME this should be simplified but will be correct for now.
		if (_playerToServe == GameState.PLAYER_ONE) {
			_player2.opponentPlayed();
		}
		if (_playerToServe == GameState.PLAYER_TWO) {
			_player1.opponentPlayed();
		}
	}

	function resetForNewServe():Void {
		_leftPaddle.x = LEFT_X;
		_leftPaddle.y = (FlxG.height - _leftPaddle.height) / 2.0;
		_rightPaddle.x = RIGHT_X;
		_rightPaddle.y = (FlxG.height - _rightPaddle.height) / 2.0;
		_ball.x = (FlxG.width - _ball.width) / 2.0;
		_ball.y = 0;
		_ball.velocity.set(0.0, 0.0);

		_player1.rallyOver();
		_player2.rallyOver();
		if (_playerToServe == GameState.PLAYER_ONE) {
			_player1.myServe = true;
		} else {
			_player2.myServe = true;
		}
	}

	override public function update(elapsed:Float):Void {
		var frameStart = Timer.stamp();

		// FIXME Checking for joins and start - this just feels like it's
		//       in the wrong place.
		if (G.gameState.gameMode == NETWORK) {
			if (_server && _listener == null) {
				startListener();
			}

			if (!_server && G.gameState.connection == null) {
				trace('starting client ');
				startClient();
			}

			if (_server && G.gameState.connection != null && !_initialized) {
				initializeGameState();
			}
		} else {
			initializeGameState();
		}

		getInputs();

		if (!_initialized
			|| _playerInputs == null
			|| _playerInputs[GameState.PLAYER_ONE] == null
			|| _playerInputs[GameState.PLAYER_TWO] == null
			|| G.gameState.currentFrame > _playerInputs[GameState.PLAYER_ONE].framenumber
			|| G.gameState.currentFrame > _playerInputs[GameState.PLAYER_TWO].framenumber) {
			// trace('peerInputs=${peerInputs}, G.gameState.currentFrame=${G.gameState.currentFrame}, peerInputs.framenumber=${peerInputs != null ? peerInputs.framenumber : -1}');
			// No further update processing until the game is fully initialized.
			// Don't proceed if the frame numbers are out of sync
			Globals.metrics.partialFrameCount++;
			return;
		}

		super.update(elapsed);
		// trace('rightPaddle=${_rightPaddle.x}, ${_rightPaddle.y}');

		processInputs(elapsed, _playerInputs);

		FlxG.collide(_ball, _leftPaddle, (_, _) -> {
			notifyPlayer(_leftPaddle);
		});
		FlxG.collide(_ball, _rightPaddle, (_, _) -> {
			notifyPlayer(_rightPaddle);
		});

		if (_ball.y < 0) {
			_ball.velocity.bounce(FlxPoint.get(0, 1));
		}
		if (_ball.y > FlxG.height - 10) {
			_ball.velocity.bounce(FlxPoint.get(0, -1));
		}
		if (_ball.x < 0) {
			_rightPoints++;
			_rightScore.text = '${_rightPoints}';
			_rightScore.textField.antiAliasType = ADVANCED;
			_rightScore.textField.sharpness = 400;

			_playerToServe = GameState.PLAYER_TWO;
			resetForNewServe();
		}
		if (_ball.x > FlxG.width) {
			_leftPoints++;
			_leftScore.text = '${_leftPoints}';
			_leftScore.textField.antiAliasType = ADVANCED;
			_leftScore.textField.sharpness = 400;

			_playerToServe = GameState.PLAYER_ONE;
			resetForNewServe();
		}

		G.gameState.currentFrame++;
		// update metrics
		Globals.metrics.frameTimes.push(Timer.stamp() - frameStart);
		Globals.metrics.frameCount++;
	}

	/**
	 * Find the owner of the paddle that just hit the ball and notify the
	 * other player.
	 * 
	 * FIXME - this could be done better if the paddle/player mapping stuff
	 *         got better sorted. But this will at least be correct for now.
	 * @param paddle 
	 */
	function notifyPlayer(paddle:Paddle):Void {
		if (_player1.paddle == paddle) {
			_player2.opponentPlayed();
		}
		if (_player2.paddle == paddle) {
			_player1.opponentPlayed();
		}
	}

	function getInputs():Void {
		for (player in [_player1, _player2]) {
			_playerInputs[player.id] = player.getInput();
		}
	}

	function processInputs(elapsed:Float, inps:Array<PlayerInputs>):Void {
		// FIXME this still hardcodes the player paddle mapping
		// Process left hand player - server player
		if (inps[GameState.PLAYER_ONE].up) {
			leftPaddleMove(0, -200 * elapsed);
		}
		if (inps[GameState.PLAYER_ONE].down) {
			leftPaddleMove(0, 200 * elapsed);
		}
		// Process right hand player - client player
		if (inps[GameState.PLAYER_TWO].up) {
			rightPaddleMove(0, -200 * elapsed);
		}
		if (inps[GameState.PLAYER_TWO].down) {
			rightPaddleMove(0, 200 * elapsed);
		}
		// Dual player on one keyboard - comment for now
		// if (FlxG.keys.pressed.O) {
		// 	rightPaddleMove(0, -200 * elapsed);
		// }
		// if (FlxG.keys.pressed.K) {
		// 	rightPaddleMove(0, 200 * elapsed);
		// }
		if (inps[GameState.PLAYER_ONE].serve || inps[GameState.PLAYER_TWO].serve) {
			serve((FlxG.width) / 2.0, 0, 200, -30);
		}
	}
}
