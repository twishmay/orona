###
Orona, © 2010 Stéphan Kochen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
###

# Orona uses two WebSocket connections during play. The first is the lobby connection, which is
# always open, and is also used for in-game chat. The second is used for world synchronization,
# which is kept separate so that the lobby connection cannot impede network performance of game
# updates (or at least diminish the effect).

# The collecting of data of world updates is governed by this module. World updates are split up
# in two kinds of messages.

# The first are critical updates, which are object creation an destruction. Both the server and
# client have lists of objects that are kept in sync. In order to do that, these updates are
# transmitted reliably to clients. (But actual transport is not done by this module.)

# The second are attribute updates for existing objects. A single update message of this kind
# (currently) contains a complete set of updates for all world objects. There are no differential
# updates, so it's okay for the underlying transport to drop some of these.

# In order to do the right thing in different situations without complicating simulation code,
# a global networking context object is used that handles all networking state. The simulation
# only calls into a couple of methods, and is ignorant of what happens from there.

# FIXME: still missing here is synchronization of pills and bases.
# Perhaps those should be objects too?


# The interface provided by network contexts. Unused, but here for documentation.
class Context
  constructor: (sim) ->

  # This class attribute tells whether the context type is for a simulation authority.
  # The simulation will leave certain actions only to the authority, such as respawning.
  # It should be simply yes or no.
  authority: null

  # Called when the context is activated. See 'inContext' for more information.
  activated: ->

  # Notification sent by the simulation that the given object was created.
  created: (obj) ->

  # Notification sent by the simulation that the given object was destroyed.
  destroyed: (obj) ->

  # Notification sent by the simulation that the given map cell has changed.
  mapChanged: (cell, oldType, hadMine) ->


# All updates are processed by the active context.
activeContext = null

# Call +cb+ within the networking context +context+. This usually wraps calls to things that
# alter the simulation.
inContext = (ctx, cb) ->
  activeContext = ctx
  ctx.activated()
  retval = cb()
  activeContext = null
  # Pass-through the return value of the callback.
  retval


# Exports.
exports.inContext       = inContext

# Delegate the functions used by the simulation to the active context.
exports.isAuthority = -> if activeContext? then activeContext.authority else yes
exports.created     = (obj) -> activeContext?.created(obj)
exports.destroyed   = (obj) -> activeContext?.destroyed(obj)
exports.mapChanged  = (cell, oldType, hadMine) -> activeContext?.mapChanged(cell, oldType, hadMine)

# These are the server message identifiers both sides need to know about.
# The server sends binary data (encoded as base64). So we need to compare character codes.
exports.WELCOME_MESSAGE   = 'W'.charCodeAt(0)
exports.CREATE_MESSAGE    = 'C'.charCodeAt(0)
exports.DESTROY_MESSAGE   = 'D'.charCodeAt(0)
exports.MAPCHANGE_MESSAGE = 'M'.charCodeAt(0)
exports.UPDATE_MESSAGE    = 'U'.charCodeAt(0)

# And these are the client's messages. The client just sends one-character ASCII messages.
exports.START_TURNING_CCW  = 'L'; exports.STOP_TURNING_CCW  = 'l'
exports.START_TURNING_CW   = 'R'; exports.STOP_TURNING_CW   = 'r'
exports.START_ACCELERATING = 'A'; exports.STOP_ACCELERATING = 'a'
exports.START_BRAKING      = 'B'; exports.STOP_BRAKING      = 'b'
exports.START_SHOOTING     = 'S'; exports.STOP_SHOOTING     = 's'
