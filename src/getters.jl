#=
    Contents: Getters for ConnectionPool
=#

#=type ConnectionPool
    connection_prototype    # A disconnected instance of the connection
    target_lb::Int64        # Lower bound of target number of connections in the pool
    target_ub::Int64        # Upper bound of target number of connections in the pool
    peak::Int64             # Peak number of connections in the pool 
    unoccupied::Set         # The set of connections in the pool that are not being used
    occupied::Set           # The set of connections in the pool that are being used
    ms_wait::Int64          # If all connections are busy, how long to wait (ms) before trying to connect again
    n_tries::Int64          # How many times to retry acquiring a connection
end =#

"""
Gets a connection from the pool if one is available, else returns 0.
"""
function get_connection!(cp)
    result = 0
    if length()

    result
end


function get_n_unoccupied(cp)
    length(cp.unoccupied)
end

function get_n_occupied(cp)
    length(cp.occupied)
end

"Number of connections, occupied or not."
function get_n_connections(cp)
    get_n_unoccupied(cp) + get_n_occupied(cp)
end

function get_target_lower(cp)
    cp.target_lb
end

function get_target_upper(cp)
    cp.target_ub
end

function get_peak(cp)
    cp.peak
end

function get_wait(cp)
    cp.ms_wait
end

function get_n_tries(cp)
    cp.n_tries
end


# EOF
