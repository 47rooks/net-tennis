package player;

import utils.Globals.G;
import haxe.io.Bytes;

class NetworkPlayer extends Player {
	public function new(id:Int) {
		super(id, NETWORK_PLAYER);
	}

	override public function getInput():Null<PlayerInputs> {
		// trace('getting NetworkPlayer.getInput (${id})');
		return receiveMessage();
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
	function receiveMessage():Null<PlayerInputs> {
		var b:Bytes = null;
		var loopCnt = 5;
		var inp = null;
		while (b == null && loopCnt > 0 && G.gameState.connection != null) {
			// if (_server) {
			// 	if (_peer != null) {
			// 		b = _peer.receive();
			// 	}
			// } else {
			// 	if (_client != null) {
			// 		b = _client.receive();
			// 	}
			// }
			b = G.gameState.connection.receive();
			trace('NP (${id}) received ${b}');
			if (b != null) {
				inp = new PlayerInputs();
				var data = b.getData().slice(4);
				inp.framenumber = b.getInt32(0);
				inp.up = data[0] == 1 ? true : false;
				inp.down = data[1] == 1 ? true : false;
				inp.serve = data[2] == 1 ? true : false;

				// trace('Received peer frame = ${inp.framenumber}');
				// _peerInputs.add(inp);
				break; // should only get one packet in lockstep
			}
			Sys.sleep(0.005);
			loopCnt--;
		}
		return inp;
	}
}
