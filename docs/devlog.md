# Devlog

- [Devlog](#devlog)
  - [6/8/2025 Refactor to allow single instance play](#682025-refactor-to-allow-single-instance-play)
  - [5/29/2025 A simulated player for testing](#5292025-a-simulated-player-for-testing)
    - [Behaviour Trees](#behaviour-trees)
    - [Computing the intercept point for the incoming ball](#computing-the-intercept-point-for-the-incoming-ball)
    - [BT references](#bt-references)
  - [5/16/2025 Getting to lockstep](#5162025-getting-to-lockstep)
    - [Getting connected](#getting-connected)
    - [Getting my inputs, sending my inputs, getting their inputs](#getting-my-inputs-sending-my-inputs-getting-their-inputs)
    - [Run the `update()` loop or not](#run-the-update-loop-or-not)
    - [Waiting for packets in a fixed timestep game loop](#waiting-for-packets-in-a-fixed-timestep-game-loop)


## 6/8/2025 Refactor to allow single instance play

Having gotten a basic AI opponent work it was time to look at performance metrics and start checking on frametimings, number of skipped frames due to packet misses and so on. But the problem here is that I need a way to display the metrics. My thought here was an overlay like the F3 page in Minecraft. This means I need a UI which will be HaxeUI but I didn't want to have to keep loading two instances of the game to test the UI. So I needed to get the game to play in non-networked mode. And that's what this post is about.

A number of assumptions had been made at to this point which meant that a bit of refactoring was in order. In particular only the client - second instance - supported an AI player. Further the passing of input keystrokes was pretty messy. So a little thinking about what to support was needed first.

This often happens with code that the wrong things are tied together unnecessarily and you need to pry them apart to make progress without creating a tangled mess. I had various problems.

  * the game simulation logic explicitly looked for network input for a particular paddle and I had to check in the movement code which input moved which paddle. This meant that code that could be generic was hardcoded to a paddle.
  * only one player could be an AI, the one that was playing in the second (client) instance
  * there was no easier to just say player 1 will be AI or both players will be AI
  * there was no way to run without the network. The main game loop assumed the player was networked and simply would not proceed without network packet input from the other instance
  * there was no way to have a game mode where two players played as different players on the same physical machine. This wasn't really a target use case originally but it seemed odd that it just couldn't be supported.

So after thinking about it I had the following elements that needed to be separated:

    instances of the game
    players - one or two
    paddles - left or right
    the player input - keyboard, AI, or network messages

The main game logic really only requires the notion of two players, each controlling a single paddle. So the goal seemed to be to create the main game logic around that notion and then to provide a way to produce inputs for each player each frame and pass them in as inputs for player 1 and player 2. Further it seemed sensible to make it possible that the players control different paddles, so they could play at different ends of the court. So it was necessary to be able to map players to paddles, and to map input sources to players, and then to allow this for one or two game instances.

The mapping looks like this:

```
        AI --------------
                         \
        network packet -----> player ----> paddle 
                         /
        keyboard --------
```

This structure allows a player to be a user or an AI and for the networked case to represent the remote user as a `NetworkPlayer`. The `NetworkPlayer` simply reads a message from the network connection between the two games and gets the inputs from the remote player. It doesn't matter if that remote player is a person or an AI. It also lays the groundwork to have multiple local players, though additional work is required there so they have separate input sources - different keys or separate controllers.

Now it is simple to just make sure that the `update()` function only goes on to run the game logic if there is a set of inputs from each player. If there isn't it simply aborts this update and tries on the next iteration. The use for this is where network packets are delayed for some reason. If the non-networked case this just doesn't happen.

So there are now three `*Player` classes.


| Class             | Description                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| `Player`          | The base class and the type that represents a person.                                                  |
| `SimulatedPlayer` | The AI player which generates its inputs from a Behaviour Tree AI.                                     |
| `NetworkPlayer`   | The representation of the remote player in network game mode which gets its input from a network read. |

These have to be configured at game startup. This meant updates to the command line arguments to separate the AI-ness of a player from the instance of the game and attach it to the player itself.

As happens with refactoring you hit other issues. While doing this it becamse increasingly obvious that the networking setup really was appropriate in the state but was more a property of the Game object. Flixel doesn't really expect a `FlxGame` subclass to be created, though you could do that. I opted to bloat `Main` for now and add `Globals`. I will likely have to revisit this and may well create a game level object. This would require making it possible for the state and player objects and so on to get access to game level fields. For now `Globals` is easier, as `FlxG.game` is not generic.

Additional items like moving code from `TennisState` to player classes and so on cropped up on the way.

Now we can play player vs AI on a single instance which was the main goal. This will make it simpler to test enhancments that do not require networked testing.

## 5/29/2025 A simulated player for testing

After getting basic lockstep working it was necessary to be able to play the game for some time with only me playing. This required an automated opponent. 

### Behaviour Trees

So I needed a form or state machine or AI to control the player. MondayHopscotch has been playing with Behaviour Trees (https://github.com/bitDecayGames/BehaviorTree) and I was interested to try them out. So using their package I got a BT player running that can recieve the ball, hit it back, and serve if it wins. As yet it cannot lose, but I'll fix that soon. `playerBT.drawio` or `playerBT.png` show the current BT.

BTs have the very interesting property of being evaluated in their entirety each tick. This permits reacting to changes in game state immediately. But it has significant implications for how you model the condition checks. It also implies that you must not make any single operation too expensive.

I had originally begun setting state variables in the BT context to short circuit bits of logic once it had progressed to a certain point through the tree, like when it had arrived at the intercept point. But in fact simply comparing the current position with the intercept point is enough, and only a little more expensive.

### Computing the intercept point for the incoming ball

BT node EstimateIntercept <https://github.com/47rooks/net-tennis/blob/main/source/ai/bt/EstimateIntercept.hx> computes the intercept point by taking the incoming ball velocity and rendering it into parameteric form. 

```
    x = Px + Vx * t
    y = Py + Vy * t
```
where (Px, Py) is the current position of the ball, just after the opponent hits it, (Vx, Vy) is the velocity vector (not normalized) and t is the parameter. As we know the surrounding box x and y values we can compute t using one equation and then plug that value into the other to determine the unknown either x or y.

For example, to check if the ball has hit my paddle I know that x must be the x coordinate of whichever paddle the player is controlling. We can compute t as

```
   t = (paddle.x - Px) / Vx
```

Once we have that y is computed directly by substitution. Then if y is less than zero or greater than FlxG.height we know that it didn't hit the back wall before bouncing off either the top or bottom wall. In that case we compute the collision point with the wall by using the y equation to solve for t. Then we use that to solve for x by substititution into the x equation. This tells us where along the wall the collision is.

At this point we know the ball must bounce and continue toward the player. So we compute the new velocity vector using `FlxPoint.bounce()`. Then taking the collision point as (Px, Py) we iterate and try again. We stop once we hit the receiving paddle x position.

Apart from that there is a check too many iterations to prevent infinite loops. There are edge cases not explicitly handled yet, like what happens if the ball is bouncing directly up and down. Currently this should never happen - famous last words.

But it's a start and for testing the simulated player has already revealed there are cases with the game instances can desync. I suspect this is simulation differences in the instances, rather than network desync, but I'll have to investigate.

### BT references

https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work


## 5/16/2025 Getting to lockstep

After reading various references and getting a basic understanding of what lockstep means I went ahead and tried to implement it. The basic plot was to structure the `TennisState.update()` method like this

```
    getInputs();

    sendInputsToPeer();

    receiveMessage();

    Once you have inputs for this frame allow the rest of the update to run
```

This was easier said than done. The plan with any network game is to render the same frame exactly the same to both (all) players all the time. In lockstep this is simpler because you don't render until you have the inputs from each player. The question is how do you know ? My first thought was to send messages on every frame. The problem though is that you need to ensure you get a packet from each only - you don't want one player running ahead and sending tons of packets. So I just send one packet per frame and wait for the corresponding packet from the other player. I added a framenumber to my packets so that I could check for sync. I suspect this is not really necessary for lock step once you have it running, but it helps figuring things out.

I hit a bunch of problems along the way.

### Getting connected

It simply isn't possible to get both players to start their games simultaneously and have them connect immediately. Apart from how the universe works there is the fact that one of the games has to open a listen socket for the other to connect to. So it has to start first. That leaves you with a problem of establishing sync once the second player connects. It also means that your `update()` loop has to handle the connect behaviour. My `network` package starts a `Listener` on a specified host:port. There is a thread watching the listen socket and when a connect request arrives it creates a `Server` object to represent the client session. It then sets a variable in the state indicating there is now a `Peer` to play with.

On the connecting client game instance there is a `Client` object which represents the connection to the server. At this point the two game instances can communicate.

But they do not have any notion of which frame the other is one. As nothing before this point matters, when the connect is successful both games initialize their state to the same thing. In particular they set their respective `_currentFrame` values to 0.

One gotcha here is not to do anything apart from the creation of the `Server` object in the server listener thread. This is already fraught with timing problems and you don't need the listener thread making this harder. So the initialization is done in the main thread once the `Server` object is created. If you make any assumptions about when a client will connect, when a thread will set some state or whether operations in a loop occur in one order or the other, it will bite you and very quickly.

Ok, finally we have a starting point.

### Getting my inputs, sending my inputs, getting their inputs

The abovementioned assumption about what order things happen in bit me here a bit. Should have known better. Anyhow, I had problems because sometimes I would get player 2's inputs before I sent mine, and then increment my framenumber and then send my inputs. All messed up. And as I was using framenumber to determine whether I could run the remainder of `update()` things locked up almost instantaneously.

It was necessary to either do all three of these operations in order or do none. So they have to be grouped together and protected with an `if` checking that the server and client were connected. I'll mention here too that you have to remember you are running the same code on both instances. If you are using `Server` on one end and `Client` on the other you need to check both cases properly. Something to cleanup later.

### Run the `update()` loop or not

The `TennisState.update()` looks like this schematically

```
Start server or client

    Get my inputs
    Send my inputs to peer
    Read peers inputs from network

Check whether to actually simulate - run the game update loop
    if not, return

super.update()

Process the inputs from each player
    for example, move the paddles or serve the ball

Do collision detection and handling

Increment the _currentFrame number
```
Once I have both a server and a client and new local inputs and new remote
inputs from the other player, and the local and remote framenumbers are the same I run the rest of the loop. I process user inputs and move the paddles or start the ball moving. If the framenumbers don't match I cut the `TennisState.update()` method short and return at that point. This allows me to get the inputs from the network even if it takes a few frames.

The `_currentFrame` number is updated at the bottom of the frame so that won't happen until I process a matched pair of inputs, inputs from both players for the same frame.

Strictly in lock step you can probably just iterate only on receipt of the new message, so this is likely more complicated that it needs to be. That's what you get for developing it from scratch and debugging your way to working.

### Waiting for packets in a fixed timestep game loop

I was just cleaning up so code hacks. One of those was that in my `receiveMessage()` function I had a loop doing up to 5 receive calls to get messages. As soon as I got one I would exit and continue the update loop. I removed that and the game slowed down ! I love it when the counterintuitive happens. So the reason was interesting. When you do one recieve per loop in a 60 FPS fixed tick game loop if there is nothing you don't check again for 16ms. But even with a 10ms sleep in the receive message inner loop you can get a new message within 10ms evey loop. It makes a noticeable difference. Obviously a blocking read call would make it faster. Well, right until it blocks indefinitely. So a blocking read is not really viable as you cannot unblock the thread when needed. A second thread lies in the future, for sure, but not now.

So the solution for now is a 5ms sleep and a 3 iteration inner loop. A two iteration loop is still two slow as it misses receipt on almost every loop. This will change once I test on two separate machines on the LAN. *NOTE* This may need to be tunable for testing.