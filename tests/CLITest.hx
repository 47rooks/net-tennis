package;

import haxe.ValueException;
import sys.io.Process;
import utest.Assert;
import utest.Test;

@:access(Main.parseCliArgs)
class CLITest extends Test {
	var _m:Main;

	function setup():Void {
		_m = new Main();
	}

	function testIpPort() {
		_m.parseCliArgs(["-i", "127.0.0.1", "-p", "5000"]);
		@:privateAccess Assert.equals(5000, _m._port);
		@:privateAccess Assert.equals("127.0.0.1", _m._ipAddr);
	}

	function testIpOnly() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-i", "127.0.0.1"]);
			} catch (e:ValueException) {
				Assert.equals("Either ipAddr and port must be specified, or neither must be specified.", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testPortOnly() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-p", "5000"]);
			} catch (e:ValueException) {
				Assert.equals("Either ipAddr and port must be specified, or neither must be specified.", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testInvalidPort() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-p", "notaportnumber"]);
			} catch (e:ValueException) {
				Assert.equals("Invalid port number: notaportnumber", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testInvalidIp() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-i", "notanip", "-p", "5000"]);
			} catch (e:ValueException) {
				Assert.equals("Bad IP: notanip", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testInvalidArgs() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-ipAddr", "127.0.0.1", "-port", "5000"]);
			} catch (e:ValueException) {
				Assert.equals("Invalid argument found -ipAddr", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testInvalidServer() {
		Assert.raises(() -> {
			try {
				_m.parseCliArgs(["-s"]);
			} catch (e:ValueException) {
				Assert.equals("-s may only be specified with -i and -p", e.value);
				throw e;
			}
		}, ValueException);
	}

	function testValidClientAIPlayer1() {
		_m.parseCliArgs(["--p1", "ai"]);

		@:privateAccess Assert.isTrue(_m._player1AI);
	}

	function testValidClientAIPlayer2() {
		_m.parseCliArgs(["--p2", "ai"]);

		@:privateAccess Assert.isTrue(_m._player2AI);
	}

	function testIpPortServerAI() {
		_m.parseCliArgs(["-i", "127.0.0.1", "-p", "5000", "-s", "--p1", "ai"]);
		@:privateAccess Assert.equals(5000, _m._port);
		@:privateAccess Assert.equals("127.0.0.1", _m._ipAddr);
		@:privateAccess Assert.isTrue(_m._player1AI);
	}

	function testDoubleAI() {
		_m.parseCliArgs(["--p1", "ai", "--p2", "ai"]);

		@:privateAccess Assert.isTrue(_m._player1AI);
		@:privateAccess Assert.isTrue(_m._player2AI);
	}
}

class SubProcessCLITests extends Test {
	function testHelp() {
		var p = new Process("export/linux/bin/NetTennis", ["-h"]);
		Assert.equals("NetTennis [-h] [-i IP address -p port [-s]] [--p1 ai][--p2 ai]", p.stdout.readLine());
	}
}
