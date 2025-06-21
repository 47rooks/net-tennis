package;

import haxe.ui.Toolkit;
import player.NetworkPlayer;
import player.SimulatedPlayer;
import player.Player;
import utils.GameState;
import utils.Globals.G;
import crashdumper.CrashDumper;
import crashdumper.SessionData;
import haxe.ValueException;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
	var _ipAddr:Null<String> = null;
	var _port:Null<Int> = null;
	var _server:Bool = false;
	var _player1AI:Bool = false;
	var _player2AI:Bool = false;

	public function new() {
		super();

		var unique_id:String = SessionData.generateID("NetTennis_");
		var crashDumper = new CrashDumper(unique_id);

		parseCliArgs(Sys.args());

		var player1:Player;
		var player2:Player;
		if (_player1AI) {
			player1 = new SimulatedPlayer(GameState.PLAYER_ONE);
		} else {
			player1 = new Player(GameState.PLAYER_ONE, USER);
		}
		if (_player2AI) {
			player2 = new SimulatedPlayer(GameState.PLAYER_TWO);
		} else {
			player2 = new Player(GameState.PLAYER_TWO, USER);
		}
		if (_ipAddr != null) {
			if (_server) {
				player2 = new NetworkPlayer(GameState.PLAYER_TWO);
			} else {
				player1 = new NetworkPlayer(GameState.PLAYER_ONE);
			}
		}

		if (_ipAddr != null) {
			G.gameState.gameMode = NETWORK;
		} else {
			G.gameState.gameMode = LOCAL;
		}

		// Initialize HaxeUI before creating the FlxGame
		Toolkit.init();

		addChild(new FlxGame(0, 0, () -> {
			return new TennisState(_ipAddr, _port, _server, player1, player2);
		}));
	}

	function parseCliArgs(args:Array<String>):Void {
		final PROGRAM_PATH = Sys.programPath();
		var PROGRAM = PROGRAM_PATH.indexOf('/') != -1 ? PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('/') +
			1) : PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('\\')
			+ 1);

		final USAGE = '${PROGRAM} [-h] [-i IP address -p port [-s]] [--p1 ai][--p2 ai]\n'
			+ '-h            Print this usage message\n'
			+ '-i <IP_ADDR>  IP address to listen on or connect to\n'
			+ '-p <PORT>     port number to listen on or connect to\n'
			+ '-s            start as server and listen on ip:port\n'
			+ '              if not specified then connect to ip:port\n'
			+ '--p1 ai       player 1 is an AI. Only used on server if networked.\n'
			+ '--p2 ai       player 2 is an AI Only used on client if networked.\n';

		var i = 0;
		while (i < args.length) {
			if (args[i] == "-h") {
				Sys.println(USAGE);
				Sys.exit(0);
			} else if (args[i] == "-i") {
				i++;
				// Validate IP as v4 only for now
				var re = ~/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/;
				if (!re.match(args[i])) {
					throw new ValueException('Bad IP: ${args[i]}');
				}
				_ipAddr = args[i];
			} else if (args[i] == "-p") {
				i++;
				_port = Std.parseInt(args[i]);
				if (_port == null) {
					throw new ValueException('Invalid port number: ${args[i]}');
				}
			} else if (args[i] == "-s") {
				_server = true;
			} else if (args[i] == "--p1" && args[i + 1] == "ai") {
				_player1AI = true;
				i++;
			} else if (args[i] == "--p2" && args[i + 1] == "ai") {
				_player2AI = true;
				i++;
			} else {
				throw new ValueException('Invalid argument found ${args[i]}');
			}
			i++;
		}

		if ((_ipAddr != null && _port == null) || (_ipAddr == null && _port != null)) {
			throw new ValueException("Either ipAddr and port must be specified," + " or neither must be specified.");
		} else if (_server && (_ipAddr == null || _port == null)) {
			throw new ValueException("-s may only be specified with -i and -p");
		} else if (_ipAddr != null && _port != null) {
			Sys.println('ip=${_ipAddr}, port=${_port}, server=${_server}');
		}
	}
}
