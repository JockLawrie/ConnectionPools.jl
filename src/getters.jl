#=
    Contents: Getters for ConnectionPool.
=#


"""
Gets a connection from the pool if one is available, else returns 0.

Notes:
- Set target lower and (finite) upper bounds on the number of connections in the pool under typical usage.
- Set a (finite) peak number of connections, the absolute maximum number of connections that can be made.
- Reset the target and peak numbers as desired (the peak is constrained to be at least as large as the target upper bound).
- When requesting a connection from the pool:
    - If the target upper bound has not been reached, get a connection from the `unoccupied` set if there is one, otherwise create a new one.
    - If the target upper bound has been reached:
        - If the peak number has not been reached, create a new connection and delete it when finished.
        - If the peak number has been reached, wait `ms_wait` ms and try again to acquire a connection.
        - Try a maximum of `n_tries` times to acquire a connection from the pool.
        - If all attempts to acquire a connection fail, return cp.connection_prototype (which is disconnected)
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
    else
	if get_n_unoccupied(cp) == 0                          # If no connection available, wait and try again
	    s = 0.001 * get_n_tries(cp)
	    for i = 1:cp.n_tries
		sleep(s)
		if get_n_unoccupied(cp) > 0
		    result = pop!(cp.unoccupied)
		    push!(cp.occupied, result)
		    break
		end
	    end
	else                                                  # If connection available, use it
	    result = pop!(cp.unoccupied)
	    push!(cp.occupied, result)
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

function get_target_lower(cp::ConnectionPool)
    cp.target_lb
end

function get_target_upper(cp::ConnectionPool)
    cp.target_ub
end

function get_peak(cp::ConnectionPool)
    cp.peak
end

function get_wait(cp::ConnectionPool)
    cp.ms_wait
end

function get_n_tries(cp::ConnectionPool)
    cp.n_tries
end


# EOF
