# Stuff to Do

   * give player control over bounce angle somehow
   * two modes of single instance play - with sim or two local players
     * two local players requires the ability to map each player to different inputs
   * players
     * allow either player to be on either server or client when networked
       * requires a protocol negotiation to check for a clash
       * may not be a good idea anyway
   * add gamepad support
   * reskin game and enlarge - basic dev art required
   * Sim player
     * work for player 1 (left hand player)
       * principal problem is setting incoming/outgoing directions based on paddle
     * able to lose
   * ball
     * simulate ball rise and fall in plan view - so change size as it moves
     * introduce bounce
     * allow bounce over receiver
     * fix serve direction - it always goes the same way regardless of which player serves
   * stats/metrics
     * define and measure metrics using macros
     * add way to define and compute stats
     * add network, fps and sync related metrics
   * testing
     * CLI argument tests need updating
