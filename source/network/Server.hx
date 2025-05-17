package network;

import sys.net.Socket;

/**
 * The server end of a connected pair. In general the only difference
 * between a `Server` and a `Client` is that a server does not have a
 * connect operation. It is expected that a `Server` object will be
 * created in response to a `Listener` connection accept.
 */
class Server extends Peer
{
	public function new(socket:Socket)
	{
		super();
		_socket = socket;
		connected = true;
	}
}
