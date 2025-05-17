package network;

import haxe.ValueException;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Error;
import network.NetworkException.NetworkError;
import sys.net.Socket;

/**
 * A Peer is a base class for socket endpoints and supports all the basic
 * network operations.
 */
class Peer {
	var _socket:Socket = null;

	public var connected(default, null):Bool;

	/**
	 * Constructor.
	 */
	public function new() {
		connected = false;
	}

	/**
	 * Receive a all available bytes on the socket.
	 * 
	 * @return the bytes received or null if no data is available.
	 */
	public function receive():Null<Bytes> {
		if (_socket == null) {
			// FIXME - should this be an exception ?
			return null;
		}

		var bb = new BytesBuffer();
		try {
			var done = false;
			var totalBytes = 0;
			while (!done) {
				var b = Bytes.alloc(200);
				var numBytes = _socket.input.readBytes(b, 0, 200);
				if (numBytes < 200) {
					done = true;
				}

				bb.addBytes(b, 0, numBytes);
				totalBytes += numBytes;
				// trace('${Sys.time()}:numBytes=${numBytes} received');
			}
		} catch (ioe:Error) {
			var err = Std.string(ioe);
			if (err != "Blocked") {
				close();
				throw NetworkException.fromError(ioe);
			}
			// trace('IO error blocked');
		} catch (e:Dynamic) {
			trace('Got exception: ${e}');
			close();
			throw NetworkException.fromError(e);
		}
		return bb.length > 0 ? bb.getBytes() : null;
	}

	/**
	 * Send a message to the endpoint this peer is connected to.
	 * @param msg the message to send
	 * @throws NetworkException if not connected
	 */
	public function send(msg:Bytes):Void {
		if (_socket != null) {
			try {
				// trace('${Sys.time()}:msg=${msg.length} sending');

				_socket.output.writeBytes(msg, 0, msg.length);
				_socket.output.flush();
			} catch (ioe:Error) {
				var err = Std.string(ioe);

				if (err != "Blocked") // haxe.io.Error
				{
					var t = NetworkException.fromError(ioe);
					// FIXME not sure I need this piece
					if (t.error != NetworkError.BLOCKING) {
						close();
						throw t;
					}
				}
			} catch (ve:ValueException) {
				var err = Std.string(ve);
				if (err == "Eof") {
					// FIXME Doesn't this mean the client is gone ?
					// Clean up client ? Yes but only the application ChatServer/ChatClient
					// knows what to do
					// throw new NetworkException(err, ve);
					close();
					throw NetworkException.fromError(ve);
				}
			} catch (e:Dynamic) {
				close();
				throw NetworkException.fromError(e);
			}
		} else {
			throw NetworkException.fromError(NetworkError.NOT_CONNECTED);
		}
	}

	/**
	 * Disconnect from the other end.
	 */
	public function disconnect():Void {
		close();
		connected = false;
	}

	/**
	 * Shutdown and close the socket and make this `Peer` as not connected.
	 */
	public function close():Void {
		if (_socket != null) {
			try {
				_socket.shutdown(true, true);
				_socket.close();
				_socket = null;
				connected = false;
			} catch (e:Dynamic) {
				// This is not great but abandoning the socket will allow the GC
				// to take a crack and releasing it. Otherwise we will leak and
				// ultimately have to kill the process to free up the sockets.
				_socket = null;
				connected = false;
				throw NetworkException.fromError(e);
			}
		}
	}
}
