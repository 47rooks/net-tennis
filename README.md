# net-tennis
Network Tennis Game

This is an example network game, a really simple game, to explore network game programming.

## Production Game

The game itself is built with 

`lime build linux`

## Tests

Unit tests use `utest` and are most simply built using

```
lime build linux -Dtest -DUTEST_PRINT_TESTS
```

This will build a separate executable next to the production executable called `NetTennisTests`. Tests are then run by running

`export/linux/bin/NetTennisTests`

It is important that the production executable be built before running the tests as the tests run the production executable as a subprocess in at least one test.