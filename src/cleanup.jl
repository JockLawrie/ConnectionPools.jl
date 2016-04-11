#=
    Contents: Functions for cleaning up connection pools.
=#

"""
Sets the connection c to unoccupied if target_ub is not exceeded, otherwise removes it from the pool.

Notes:
1. The call to pop! is left in both clauses of the if statement for readability.
   A bug would arise otherwise because the freed connection would not be counted in the call to get_n_connections.
"""
function free!(cp::ConnectionPool, c)
    if get_n_connections(cp) <= get_target_upper(cp)
	pop!(cp.occupied, c)
	push!(cp.unoccupied, c)
    else
	disconnect(c)
	pop!(cp.occupied, c)
    end
end


"""
Disconnects and removes all connections in the pool and sets target_lb, target_ub and peak to 0.

Notes:
1. Requires get_n_occupied(cp) == 0.
"""
function delete!(cp::ConnectionPool)
    assert(get_n_occupied(cp) == 0)
    while get_n_unoccupied(cp) > 0
	c = pop!(cp.unoccupied)
	disconnect(c)
    end
    set_target_lower!(cp, 0)
    set_target_upper!(cp, 0)
    set_target_peak!(cp, 0)
end


# EOF
