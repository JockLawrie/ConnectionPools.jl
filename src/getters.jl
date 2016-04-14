#=
    Contents: Getters for ConnectionPool.
=#


"""
Gets a connection from the pool if one is available, else returns 0.

Notes:
- Set the target number of connections in the pool under typical usage.
- Set a (finite) peak number of connections that the pool can scale to. When these extra connections are released back to the pool they are deleted until the pool size reaches the target.
- The constraint `target_pool_size <= peak_size` is automatically enforced.
- Reset the target and peak numbers as desired.
- When requesting a connection from the pool:
    - If the target has not been reached, get a connection from the `unoccupied` set if there is one, otherwise create a new one.
    - If the target upper bound has been reached:
        - If the peak number has not been reached, create a new connection (and manually delete it when finished).
        - If the peak number has been reached, wait `ms_wait` milliseconds and try again to acquire a connection.
        - Try a maximum of `n_tries` times to acquire a connection from the pool.
        - If all attempts to acquire a connection fail, return the connection pool's connection prototype, which is a disconnected instance of the connection used to instantiate the connection pool.
"""
function get_connection!(cp::ConnectionPool)
    result = cp.connection_prototype
    if get_n_connections(cp) < get_peak(cp)
	if get_n_unoccupied(cp) == 0                          # If no connection available, create a new one
	    result = new_connection(cp.connection_prototype)
	    push!(cp.occupied, result)
	else                                                  # If connection available, use it
	    result = pop!(cp.unoccupied)
	    push!(cp.occupied, result)
	end
    else    # get_n_connections(cp) == get_peak(cp)
	s = 0.001 * get_n_tries(cp)
	for i = 1:cp.n_tries
	    sleep(s)
	    if get_n_unoccupied(cp) > 0
		result = pop!(cp.unoccupied)
		push!(cp.occupied, result)
		break
	    end
	end
    end
    result
end


function get_n_unoccupied(cp::ConnectionPool)
    length(cp.unoccupied)
end

function get_n_occupied(cp::ConnectionPool)
    length(cp.occupied)
end

"Number of connections, occupied or not."
function get_n_connections(cp::ConnectionPool)
    get_n_unoccupied(cp) + get_n_occupied(cp)
end

function get_target(cp::ConnectionPool)
    cp.target_pool_size
end

function get_peak(cp::ConnectionPool)
    cp.peak_size
end

function get_wait(cp::ConnectionPool)
    cp.ms_wait
end

function get_n_tries(cp::ConnectionPool)
    cp.n_tries
end


# EOF
