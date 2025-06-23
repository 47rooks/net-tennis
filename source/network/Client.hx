package network;

import haxe.ValueException;
import sys.net.Host;
import sys.net.Socket;

/**
 * Client represents a client peer. It permits connecting to a specified endpoint.
 */
class Client extends Peer {
	/**
	 * Constructor
	 */
	public function new() {
		super();
		_socket = new Socket();
	}

	/**
	 * Connect to a remote host and socket.
	 *
	 * @param ip the IP address or hostname to connect to
	 * @param port the port number to connect to
	 */
	public function connect(ip:Host, port:Int) {
		try {
			_socket.connect(ip, port);
			_socket.setBlocking(false);
			_socket.setFastSend(true);
			connected = true;
		} catch (ve:ValueException) {
			var err = Std.string(ve);
			if (err == "EOF") {
				throw NetworkException.fromError(ve);
			}
		}
	}
}
