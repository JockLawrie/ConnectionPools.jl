#=
    Contents: Setters for ConnectionPool.
=#


"""
Sets cp.target_pool_size and adjusts peak_size if necessary to ensure target_pool_size <= peak_size.

Notes:
1. After setting cp.target_pool_size:
   - Ensure target_pool_size <= peak_size.
   - Ensure that get_n_connections(cp) <= peak. But this is already the case, so do nothing.
"""
function set_target!(cp::ConnectionPool, n::Int)
    cp.target_pool_size = n
    cp.target_pool_size > cp.peak_size && set_peak!(cp, n)      # Increase peak_size to new target_pool_size
end


function set_peak!(cp::ConnectionPool, n::Int)
    assert(isfinite(n))
    cp.peak_size = n
    cp.target_pool_size > cp.peak_size && set_target!(cp, n)    # Lower target_pool_size to new peak_size
end


function set_wait!(cp::ConnectionPool, n::Int)
    cp.ms_wait = n
end


function set_n_tries!(cp::ConnectionPool, n::Int)
    cp.n_tries = n
end

# EOF
