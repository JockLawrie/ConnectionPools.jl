#=
    Contents: Setters for ConnectionPool.

    Notes:
    1. An error is raised if cp.target_lb <= cp.target_ub <= cp.peak is not satisfied.
=#


"""
Sets cp.target_lb and adjusts cp.unoccupied accordingly if necessary.

Notes:
1. After setting cp.target_lb:
   - Ensure target_lb <= target_ub <= peak.
   - Ensure that get_n_connections(cp) >= new_lb:
       - If new_lb <= old_lb, do nothing because get_n_connections(cp) >= new_lb, which is valid.
       - If new_lb > old_lb and get_n_connections(cp) < new_lb, add new connections to the pool so that get_n_connections(cp) == new_lb.
"""
function set_target_lower!(cp, n)
    cp.target_lb = n
    check_constraints(cp)
    n_new = max(0, n - get_n_connections(cp))    # Number of new connections to add to the pool
    if n_new > 0
	for i = 1:n_new
	    c = new_connection(cp.connection_prototype)
	    push!(cp.unoccupied, c)
	end
    end
end


"""
Sets cp.target_ub and adjusts cp.unoccupied accordingly if necessary.

Notes:
1. After setting cp.target_lb:
   - Ensure target_lb <= target_ub <= peak.
   - Ensure that get_n_connections(cp) <= peak. But this is already the case, so do nothing.
"""
function set_target_upper!(cp, n)
    cp.target_ub = n
    check_constraints(cp)
end


function set_peak!(cp, n)
    cp.peak = n
end

function set_wait!(cp, n)
    cp.ms_wait = n
end

function set_n_tries!(cp, n)
    cp.n_tries = n
end

# EOF
