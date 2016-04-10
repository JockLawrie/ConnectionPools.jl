#=
    Contents: Functions for creating a new connection to various databases, given an existing connection (which may or may not be connected).
=#


################################################################################
### Redis

function new_connection(c::RedisConnection)
    RedisConnection(host = c.host, port = c.port, password = c.password, db = c.db)
end


# EOF
