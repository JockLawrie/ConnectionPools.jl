#=
    Contents: Given an existing connection object (c) whose status may or may not be connected, this file provides the following functions:
              1. new_connection(c), returns a new connection with connected status.
	      2. disconnect(c), disconnects c.
=#

using Redis

function ConnectionPools.new_connection(c::RedisConnection)
    RedisConnection(host = c.host, port = c.port, password = c.password, db = c.db)
end

function ConnectionPools.disconnect(c::RedisConnection)
    disconnect(c)
end

# EOF
