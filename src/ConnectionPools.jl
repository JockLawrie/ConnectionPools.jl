module ConnectionPools

type ConnectionPool
    connection_prototype    # A disconnected instance of the connection
    target_lb::Int64        # Lower bound of target number of connections in the pool
    target_ub::Int64        # Upper bound of target number of connections in the pool
    peak::Int64             # Peak number of connections in the pool 
    unoccupied::Set         # The set of connections in the pool that are not being used
    occupied::Set           # The set of connections in the pool that are being used
    ms_wait::Int64          # If all connections are busy, how long to wait (ms) before trying to connect again
    n_tries::Int64          # How many times to retry acquiring a connection
end

end # module
