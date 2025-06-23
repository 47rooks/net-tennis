package network;

import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;

/**
 * Create a Listener to listener on a socket. Connections made successfully will call
 * `onConnect()` with the new `Server` connected to the client. Errors are reported via
 * the `onError()` callback and the `Listener` should be thrown away if an error is reported.
 * The `Listener` object will close the listen socket and the thread will end. The object will
 * be unusable after that. If the application wants to reopen the socket a new `Listener`
 * must be created.
 */
class Listener {
	var _listenSocket:Socket = null;
	var _keepListening = true;

	final LOOPBACK:Host = new Host("127.0.0.1");
	final LISTEN_PORT = 5000;
	final MAX_LISTEN = 10;

	var _onConnect:(Server) -> Void;
	var _onError:(NetworkException) -> Void;

	/**
	 * Constructor
	 * @param ip the IP address or hostname to listen on
	 * @param port the port number to listen on.
	 * @param onConnect callback function to handle successful connection
	 * @param onError callback function to handle network errors
	 */
	public function new(ip:Host, port:Int, onConnect:(Server) -> Void, onError:(ne:NetworkException) -> Void) {
		_onConnect = onConnect;
		_onError = onError;

		// Spawn listener thread
		Thread.create(() -> {
			try {
				_listenSocket = new Socket();
				_listenSocket.bind(ip, port);
				_listenSocket.listen(MAX_LISTEN);

				trace('server listening on ${_listenSocket.host().host}');
				while (_keepListening) {
					var rv = Socket.select([_listenSocket], null, null, 0.1);
					if (rv.read.length == 1 && rv.read[0] == _listenSocket) {
						var socket = _listenSocket.accept();
						socket.setBlocking(false);
						socket.setFastSend(true);
						_onConnect(new Server(socket));
					}
				}
				// Close listen socket
				_listenSocket.shutdown(true, true);
				_listenSocket.close();
				_listenSocket = null;
			} catch (err:Dynamic) {
				// Close listen socket
				_listenSocket.shutdown(true, true);
				_listenSocket.close();
				_listenSocket = null;

				onError(NetworkException.fromError(err));
			}
		});
	}

	/**
	 * Shutdown the listener. There is no way to restart it, so at this point the
	 * Listener instance should be discarded and a new one created if you need to
	 * start listening again. `shutdown()` should be called before garbage collection
	 * so as to not leak sockets.
	 */
	public function shutdown():Void {
		_keepListening = false;
	}
}
