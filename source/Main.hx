package;

// import crashdumper.CrashDumper;
// import crashdumper.SessionData;
import haxe.ValueException;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	var _ipAddr:Null<String> = null;
	var _port:Null<Int> = null;
	var _server:Bool = false;

	public function new()
	{
		super();

		// var unique_id:String = SessionData.generateID("NetTennis_");
		// var crashDumper = new CrashDumper(unique_id);

		parseCliArgs(Sys.args());

		addChild(new FlxGame(0, 0, () -> new TennisState(_ipAddr, _port, _server)));
	}

	function parseCliArgs(args:Array<String>):Void {
		final PROGRAM_PATH = Sys.programPath();
		var PROGRAM = PROGRAM_PATH.indexOf('/') != -1 ? 
			PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('/') + 1) :
			PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('\\') + 1);

		final USAGE = '${PROGRAM} [-h] [-i IP address -p port [-s]]\n' +
			'-h            Print this usage message\n' +
			'-i <IP_ADDR>  IP address to listen on or connect to\n' +
			'-p <PORT>     port number to listen on or connect to\n' +
			'-s            start as server and listen on ip:port\n' +
			'              if not specified then connect to ip:port';

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
			} else {
				throw new ValueException('Invalid argument found ${args[i]}');
			}
			i++;
		}
		if ((_ipAddr != null && _port == null) ||
		    (_ipAddr == null && _port != null)) {
			throw new ValueException("Either ipAddr and port must be specified," + " or neither must be specified.");
		} else if (_server && (_ipAddr == null || _port == null)) {
			throw new ValueException("-s may only be specified with -i and -p");
		} else if (_ipAddr != null && _port != null) {
			Sys.println('ip=${_ipAddr}, port=${_port}, server=${_server}');
		}
	}
}
