#=
    Contents: Setters for ConnectionPool.

    Notes:
    1. When setting target_lb, if target_lb <= target_ub <= peak is not satisfied then target_ub and peak are adjusted accordingly.
       Ditto when setting target_ub or peak.
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
function set_target_lower!(cp::ConnectionPool, n::Int)
    cp.target_lb = n
    cp.target_lb > cp.target_ub && set_target_upper!(cp, n)    # Increase target_ub to new target_lb
    n_new = max(0, n - get_n_connections(cp))                  # Number of new connections to add to the pool
    if n_new > 0
	for i = 1:n_new
	    c = new_connection(cp.connection_prototype)
	    push!(cp.unoccupied, c)
	end
    end
end


"""
Sets cp.target_ub and adjusts target_lb and peak if necessary to ensure target_lb <= target_ub <= peak.

Notes:
1. After setting cp.target_lb:
   - Ensure target_lb <= target_ub <= peak.
   - Ensure that get_n_connections(cp) <= peak. But this is already the case, so do nothing.
"""
function set_target_upper!(cp::ConnectionPool, n::Int)
    cp.target_ub = n
    cp.target_lb > cp.target_ub && set_target_lower!(cp, n)    # Lower target_lb to new target_ub
    cp.target_ub > cp.peak && set_peak!(cp, n)                 # Increase peak to new target_ub
end


function set_peak!(cp::ConnectionPool, n::Int)
    assert(isfinite(n))
    cp.peak = n
    cp.target_ub > cp.peak && set_target_upper!(cp, n)         # Lower target_ub to new peak
end


function set_wait!(cp::ConnectionPool, n::Int)
    cp.ms_wait = n
end


function set_n_tries!(cp::ConnectionPool, n::Int)
    cp.n_tries = n
end

# EOF
