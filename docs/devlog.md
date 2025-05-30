# Devlog

- [Devlog](#devlog)
  - [5/29/2025 A simulated player for testing](#5292025-a-simulated-player-for-testing)
    - [Behaviour Trees](#behaviour-trees)
    - [BT references](#bt-references)
  - [5/16/2025 Getting to lockstep](#5162025-getting-to-lockstep)
    - [Getting connected](#getting-connected)
    - [Getting my inputs, sending my inputs, getting their inputs](#getting-my-inputs-sending-my-inputs-getting-their-inputs)
    - [Run the `update()` loop or not](#run-the-update-loop-or-not)
    - [Waiting for packets in a fixed timestep game loop](#waiting-for-packets-in-a-fixed-timestep-game-loop)


## 5/29/2025 A simulated player for testing

After getting basic lockstep working it was necessary to be able to play the game for some time with only me playing. This required an automated opponent. 

### Behaviour Trees

So I needed a form or state machine or AI to control the player. MondayHopscotch has been playing with Behaviour Trees (https://github.com/bitDecayGames/BehaviorTree) and I was interested to try them out. So using their package I got a BT player running that can recieve the ball, hit it back, and serve if it wins. As yet it cannot lose, but I'll fix that soon. `playerBT.drawio` or `playerBT.png` show the current BT.

BTs have the very interesting property of being evaluated in their entirety each tick. This permits reacting to changes in game state immediately. But it has significant implications for how you model the condition checks. It also implies that you must not make any single operation too expensive.

I had originally begun setting state variables in the BT context to short circuit bits of logic once it had progressed to a certain point through the tree, like when it had arrived at the intercept point. But in fact simply comparing the current position with the intercept point is enough, and only a little more expensive.

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