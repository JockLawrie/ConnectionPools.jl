#=
    Contents: Constructors for ConnectionPool instances.
=#


type ConnectionPool
    connection_prototype       # A disconnected instance of the connection
    target_pool_size::Int64    # Target number of connections in the pool
    peak_size::Int64           # Peak number of connections in the pool 
    unoccupied::Set            # The set of connections in the pool that are not being used
    occupied::Set              # The set of connections in the pool that are being used
    ms_wait::Int64             # If all connections are busy, how long to wait (ms) before trying to connect again
    n_tries::Int64             # How many times to retry acquiring a connection

    """
    On creation, target_lb connections will be created
    """
    function ConnectionPool(connection, target_pool_size::Int64, peak_size::Int64, ms_wait::Int64, n_tries::Int64)
	assert(target_pool_size <= peak_size)
	assert(isfinite(peak_size))
	define_new_connection(connection)    # Includes the new_connection method for the connection type
	unoccupied = Set{typeof(connection)}()
	occupied   = Set{typeof(connection)}()
	disconnect(connection)
	new(connection, target_pool_size, peak_size, unoccupied, occupied, ms_wait, n_tries)
    end
end


function define_new_connection(connection)    # Includes the new_connection method for the connection type
    tp = string(typeof(connection))
    if tp == "Redis.RedisConnection"
	include(joinpath(dirname(@__FILE__), "supported_databases/redis_cp.jl"))
    else
	error("Unrecognized database type $tp.")
    end
end


# EOF
