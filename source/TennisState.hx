package;

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

class GameState {
	public static final PLAYER_TWO = 2;
	public static final PLAYER_ONE = 1;

	public var playerToServe:Null<Int>;

	public function new() {
		playerToServe = null;
	}
}

class PeerInputs {
	public var framenumber:Int;
	public var up:Bool;
	public var down:Bool;
	public var serve:Bool;

	public function new() {
		framenumber = -2;
		up = false;
		down = false;
		serve = false;
	}
}

class TennisState extends FlxState {
	var _ball:Ball;
	var _leftPaddle:Paddle;
	var _rightPaddle:Paddle;
	var _net:FlxSprite;
	var _leftScore:FlxText;
	var _rightScore:FlxText;

	final LEFT_X = 10;
	final RIGHT_X = FlxG.width - 20;
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
	var _peer:Null<Server> = null; // remote peer - actually a client - gotta sort names

	var _client:Null<Client> = null;
	var _clientNewCount = 0;

	var _myInputs:Null<PeerInputs> = null;
	var _peerInputs:List<PeerInputs> = null;

	// Game state vars
	var _player:Null<Int>;
	var _playerToServe:Null<Int>;
	var _initialized:Bool = false;
	var _currentFrame:Null<Int> = null;
	var _peerCurrentFrame:Null<Int> = null; // FIXME maybe remove
	var _lastFrameSent:Null<Int> = null;

	final NEW = 1;
	final CONNECTED = 2;
	final GLOBALLY_INITIALIZED = 3;
	final OUT_OF_SYNC = 4;

	var _messagingState:Null<Int> = null;

	public function new(?ipAddr:Null<String>, ?port:Null<Int>, ?server = false) {
		_ipAddr = ipAddr;
		_port = port;
		_server = server;
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

		_peerInputs = new List();
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

	function startServer():Void {
		if (_server && _listenerHost != null && _port != null) {
			_listener = new Listener(_listenerHost, _port, newClientHandler, listenerErrorHandler);
		}
	}

	function startClient():Void {
		if (!_server && _client == null && _listenerHost != null && _port != null) {
			trace('trying to connect');
			// Create a network object
			try {
				_client = new Client();
				_clientNewCount++;
				_client.connect(_listenerHost, _port);
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
				_client.close();
				_client = null;
			case INVALID_SOCKET_HANDLE:
				trace('socket no good. ${_clientNewCount}');
				_client.close();
				_client = null;
			default:
				// FIXME Client recovery
				trace('Got exception: ${ne.error}');
				_client.close();
				_client = null;
		}
	}

	/**
	 * Process an newly arrived client.
	 *
	 * This is MT safe as it inserts into a Deque which will be reaped later  
	 * by the main thread.
	**/
	public function newClientHandler(client:Server) {
		if (_peer != null) {
			client.close();
			return;
		}
		_peer = client;
		trace('${Timer.stamp()}:client connected');

		// FIXME - this needs to be handled in the server thread at the
		//         right place. We are currently skipping frame #0
		// initializeGameState();
		// Send initial setup message
		// FIXME - not quite yet but very soon
	}

	function initializeGameState():Void {
		_playerToServe = GameState.PLAYER_ONE;
		_currentFrame = 0;

		// Mark game as fully initialized.
		// No actual game play should be permitted until this point
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
	}

	function resetForNewServe():Void {
		_leftPaddle.x = LEFT_X;
		_leftPaddle.y = (FlxG.height - _leftPaddle.height) / 2.0;
		_rightPaddle.x = RIGHT_X;
		_rightPaddle.y = (FlxG.height - _rightPaddle.height) / 2.0;
		_ball.x = (FlxG.width - _ball.width) / 2.0;
		_ball.y = 0;
		_ball.velocity.set(0.0, 0.0);
	}

	override public function update(elapsed:Float):Void {
		// FIXME Checking for joins and start - this just feels like it's
		//       in the wrong place.
		if (_server && _listener == null) {
			startServer();
		}

		if (!_server && _client == null) {
			trace('starting client ');
			startClient();
		}

		if (_server && _peer != null && !_initialized) {
			initializeGameState();
		}

		if ((_server && _peer != null) || (!_server && _client != null)) {
			// Either process all or none of these steps.
			// Because a peer will appear at any point we have to ensure
			// that we do not execute, say 'receiveMessage()' if we have not
			// also called 'sendInputToPeer()'.
			getInput();

			sendInputToPeer();

			receiveMessage();
		}

		var peerInputs = _peerInputs.pop();

		if (!_initialized || peerInputs == null || _currentFrame > peerInputs.framenumber) {
			// trace('peerInputs=${peerInputs}, _currentFrame=${_currentFrame}, peerInputs.framenumber=${peerInputs != null ? peerInputs.framenumber : -1}');
			// No further update processing until the game is fully initialized.
			// Don't proceed if the frame numbers are out of sync
			return;
		}

		super.update(elapsed);

		// if (_currentFrame != _peerCurrentFrame) {
		// 	trace('DESYNC: ${_currentFrame} : ${_peerCurrentFrame}');
		// }

		processInputs(elapsed, peerInputs);

		FlxG.collide(_ball, _leftPaddle);
		FlxG.collide(_ball, _rightPaddle);

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

		_currentFrame++;
	}

	function sendInputToPeer():Void {
		trace('_lastFrameSent=${_lastFrameSent}, _currentFrame=${_currentFrame}');
		if (_lastFrameSent == null || _lastFrameSent < _currentFrame) {
			var data = new BytesBuffer();
			data.addInt32(_currentFrame);
			data.addByte(_myInputs.up ? 1 : 0);
			data.addByte(_myInputs.down ? 1 : 0);
			data.addByte(_myInputs.serve ? 1 : 0);

			if (_server) {
				if (_peer != null) {
					trace('Sending frame ${_currentFrame}');
					_peer.send(data.getBytes());
				}
			} else {
				if (_client != null) {
					trace('Sending frame ${_currentFrame}');
					_client.send(data.getBytes());
				}
			}
			_lastFrameSent = _currentFrame;
		}
	}

	/**
	 * Receive a message from the peer.
	 * 
	 * Message passing drives the game messaging state machine.
	 * 
	 * Certain message types may only be sent or received in a particular state.
	 * Both peers must be in the consistent states.
	 * 
	 * The received message must be queued for later processing or digested
	 * immediately here.
	 */
	function receiveMessage():Void {
		var b:Bytes = null;
		var loopCnt = 3;
		while (b == null && loopCnt > 0) {
			if (_server) {
				if (_peer != null) {
					b = _peer.receive();
				}
			} else {
				if (_client != null) {
					b = _client.receive();
				}
			}
			if (b != null) {
				var inp = new PeerInputs();
				var data = b.getData().slice(4);
				inp.framenumber = b.getInt32(0);
				inp.up = data[0] == 1 ? true : false;
				inp.down = data[1] == 1 ? true : false;
				inp.serve = data[2] == 1 ? true : false;

				trace('Received peer frame = ${inp.framenumber}');
				_peerInputs.add(inp);
				break; // should only get one packet in lockstep
			}
			Sys.sleep(0.005);
			loopCnt--;
		}
	}

	function getInput() {
		var inp = new PeerInputs();
		inp.framenumber = _currentFrame;
		// Keyboard input
		if (FlxG.keys.pressed.W) {
			inp.up = true;
		}
		if (FlxG.keys.pressed.S) {
			inp.down = true;
		}
		if (FlxG.keys.pressed.T && _playerToServe == _player) {
			inp.serve = true;
		}
		// Dual player on one keyboard - comment for now
		// if (FlxG.keys.pressed.O) {
		// 	rightPaddleMove(0, -200 * elapsed);
		// }
		// if (FlxG.keys.pressed.K) {
		// 	rightPaddleMove(0, 200 * elapsed);
		// }
		_myInputs = inp;
	}

	function processInputs(elapsed:Float, peerInputs:PeerInputs):Void {
		if (_server) {
			// Process left hand player - server player
			if (_myInputs.up) {
				leftPaddleMove(0, -200 * elapsed);
			}
			if (_myInputs.down) {
				leftPaddleMove(0, 200 * elapsed);
			}
			// Process right hand player - client player
			if (peerInputs.up) {
				rightPaddleMove(0, -200 * elapsed);
			}
			if (peerInputs.down) {
				rightPaddleMove(0, 200 * elapsed);
			}
		} else {
			// Process left hand player - server player
			if (peerInputs.up) {
				leftPaddleMove(0, -200 * elapsed);
			}
			if (peerInputs.down) {
				leftPaddleMove(0, 200 * elapsed);
			}
			// Process right hand player - client player
			if (_myInputs.up) {
				rightPaddleMove(0, -200 * elapsed);
			}
			if (_myInputs.down) {
				rightPaddleMove(0, 200 * elapsed);
			}
		}
		// Dual player on one keyboard - comment for now
		// if (FlxG.keys.pressed.O) {
		// 	rightPaddleMove(0, -200 * elapsed);
		// }
		// if (FlxG.keys.pressed.K) {
		// 	rightPaddleMove(0, 200 * elapsed);
		// }
		if (_myInputs.serve || peerInputs.serve) {
			serve((FlxG.width) / 2.0, 0, 200, 135);
		}
	}
}
