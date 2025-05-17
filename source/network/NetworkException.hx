package network;

import haxe.Exception;
import haxe.ValueException;
import haxe.io.Eof;
import haxe.io.Error;

/**
 * NetworkError unifies all network error codes into a single Enum to simplify
 * error handling.
 * 
 * Currently, the socket errors defined in the HXCPP Socket.cpp are covered.
**/
enum NetworkError
{
	// HXCPP Socket errors
	// FIXME these are currently hxcpp errors but really these define
	// the network package errors that you might fold haxe.io and hxcpp and others into.
	INVALID_SOCKET_HANDLE;
	BLOCKING;
	EOF;
	CONNECTION_CLOSED;
	UNKNOWN_HOST(host:String);
	UNKNOWN_AI_FAMILY;
	GAI_ERROR(host:String, gaiError:String);
	TOO_MANY_SOCKETS_SELECT;
	NO_VALID_SOCKETS;
	SELECT_ERROR(error:String);
	BIND_FAILED;
	INVALID_POLL_DATA(data:String);
	TOO_MANY_SOCKETS_POLL;
	INVALID_DATA_POSITION;
	UNKNOWN(error:String);
	BYTES_OUT_OF_BOUNDS;
	INTEGER_OVERFLOW;
	NOT_CONNECTED;
}

/**
 * NetworkException reports all networking exceptions. The primary purpose of this class
 * is to unify all the networking errors under one class to simplify handler logic.
 */
class NetworkException extends Exception
{
	/**
	 * The network error detail enum. This is usually a simple mapping from the
	 * lower layer target specific error code.
	 */
	public var error(default, null):NetworkError;

	/**
	 * This is the original object that was thrown. It could be anything which
	 * is actually part of the reason NetworkException was created. But if you need
	 * this it is preserved here.
	 */
	public var cause(default, null):Dynamic;

	/**
	 * Constructor
	 * @param error the NetworkError code for which to create this exception
	 * @param previous the causing exception class that caused this one
	 * @param cause the causing Dynamic if it's not an Exception.
	 * @param native any native error information
	 */
	function new(error:NetworkError, ?previous:Exception, ?cause:Dynamic, ?native:Any)
	{
		super(Std.string(error), previous, native);
		this.error = error;
		this.cause = cause;
	}

	/**
	 * Convert an error object to a NetworkException
	 * @param err the original error object that was thrown
	 * @return NetworkException
	 */
	static public function fromError(err:Dynamic):NetworkException
	{
		switch (err)
		{
			case Std.isOfType(_, NetworkError) => true:
				return new NetworkException(err);
			case Std.isOfType(_, Eof) => true:
				return new NetworkException(NetworkError.EOF);
			case Std.isOfType(_, Error) => true:
				switch (cast(err, Error))
				{
					case Blocked:
						return new NetworkException(NetworkError.BLOCKING);
					case OutsideBounds:
						return new NetworkException(NetworkError.BYTES_OUT_OF_BOUNDS);
					case Overflow:
						return new NetworkException(NetworkError.INTEGER_OVERFLOW);
					case Custom(e):
						return new NetworkException(NetworkError.UNKNOWN(Std.string(e)));
				}
			case Std.isOfType(_, ValueException) => true: // hxcpp via hx::Throw <some string>
				var message = Std.string(err);
				var gaiErrorRE = ~/^(.*):(.*)/;
				switch (message)
				{
					case "Invalid socket handle":
						return new NetworkException(NetworkError.INVALID_SOCKET_HANDLE, err);
					case "Blocking": // Socket
						return new NetworkException(NetworkError.BLOCKING, err);
					case "EOF": // Socket
						return new NetworkException(NetworkError.EOF, err);
					case "Connection closed":
						return new NetworkException(NetworkError.CONNECTION_CLOSED, err);
					case _.indexOf("Unknown host:") => 0:
						// case "Unknown host:") + host );
						return new NetworkException(NetworkError.UNKNOWN_HOST(message.substr(13)), err);
					case "Unkown ai_family":
						// case "Unkown ai_family") );
						return new NetworkException(NetworkError.UNKNOWN_AI_FAMILY, err);
					case gaiErrorRE.match(_) => true:
						// case host + HX_CSTRING(":") + String(gai_strerror(err)) );
						return new NetworkException(NetworkError.GAI_ERROR(gaiErrorRE.matched(1), gaiErrorRE.matched(2)), err);
					case "Too many sockets in select":
						return new NetworkException(NetworkError.TOO_MANY_SOCKETS_SELECT, err);
					case "No valid sockets":
						return new NetworkException(NetworkError.NO_VALID_SOCKETS, err);
					case _.indexOf("Select error ") => 0:
						// Handle both select error cases
						// "Select error ": // + String((int) WSAGetLastError())
						// "Select error ": // + String((int) errno));
						return new NetworkException(NetworkError.SELECT_ERROR(message.substr(13)), err);
					case "Bind failed":
						return new NetworkException(NetworkError.BIND_FAILED, err);
					case _.indexOf("Invalid polldata:") => 0:
						// hx::Throw(HX_CSTRING("Invalid polldata:") + o);
						return new NetworkException(NetworkError.INVALID_POLL_DATA(message.substr(17)), err);
					case "Too many sockets in poll":
						return new NetworkException(NetworkError.TOO_MANY_SOCKETS_POLL, err);
					case "Invalid data position":
						return new NetworkException(NetworkError.INVALID_DATA_POSITION, err);
					default:
						return new NetworkException(NetworkError.UNKNOWN('ve:${message}'), err);
				}
			case Std.isOfType(_, Exception) => true:
				return new NetworkException(NetworkError.UNKNOWN('Exception:${Std.string(err)}'), err);
			case Std.isOfType(_, Dynamic) => true:
				return new NetworkException(NetworkError.UNKNOWN('Dynamic:${Std.string(err)}'), null, err);
			default:
				return new NetworkException(NetworkError.UNKNOWN('default:${Std.string(err)}'), null, err);
		}
	}
}
