package utils;

import network.Peer;

enum GameMode {
	/**
	 * Two players on the same instance.
	 * Two controllers or shared keyboard on same computer
	 */
	LOCAL;

	/**
	 * One player against AI locally
	 */
	// LOCAL_AI;

	/**
	 * Network two player mode
	 */
	NETWORK;

	/**
	 * Network, one player AI
	 */
	// NETWORK_AI;
}

class GameState {
	/**
	 * Player numbers are currently significant as they are used as
	 * offsets into the _playerInputs array in TennisState.
	 */
	public static final PLAYER_ONE = 0;

	public static final PLAYER_TWO = 1;

	public var playerToServe:Null<Int>;

	public var gameMode:Null<GameMode>;

	public var currentFrame:Null<Int> = null;

	public var connection:Null<Peer> = null;
	public var lastFrameSent:Null<Int> = null;

	public function new() {
		playerToServe = null;
	}
}
