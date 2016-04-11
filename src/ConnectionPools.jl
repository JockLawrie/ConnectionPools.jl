module ConnectionPools

export ConnectionPool,
    # Getters
       get_connection!,
       get_n_connections,
       get_n_unoccupied,
       get_n_occupied,
       get_target_lower,
       get_target_upper,
       get_peak,
       get_wait,
       get_n_tries,
    # Setters
       set_target_lower!,
       set_target_upper!,
       set_peak!,
       set_wait!,
       set_n_tries!,
    # Cleaning up
       free!,
       delete!


include("new_connections.jl")
include("getters.jl")
include("setters.jl")
include("cleanup.jl")


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


"""
On creation, target_lb connections will be created
"""
function ConnectionPool(connection, target_lb::Int64, target_ub::Int64, peak::Int64, ms_wait::Int64, n_tries::Int64)
    assert(target_lb <= target_ub)
    assert(target_ub <= peak)
    assert(isfinite(peak))
    unoccupied = Set{typeof(connection)}()
    occupied   = Set{typeof(connection)}()
    if target_lb == 0
	c0 = connection
	disconnect(c0)
    else
	c0 = deepcopy(connection)
	disconnect(c0)
	push!(unoccupied, connection)
	if target_lb > 1
	    for i = 2:target_lb
		c = deepcopy(connection)
		push!(unoccupied, c)
	    end
	end
    end
    new(c0, target_lb, target_ub, peak, unoccupied, occupied, ms_wait, n_tries)
end


end # module
