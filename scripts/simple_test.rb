require 'msgr'

Msgr.start

100.times { Msgr.publish 'route.ing.key', 'message' }


