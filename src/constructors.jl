#=
    Contents: Constructors for various database types

    Notes:
    1. On creation, target_lb connections will be created
=#


################################################################################
### Redis
function ConnectionPool(connection::RedisConnection, target_lb::Int64, target_ub::Int64, peak::Int64, ms_wait::Int64, n_tries::Int64)
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
		c = typeof(c0)(host = c0.host, port = c0.port, password = c0.password, db = c0.db)
		push!(unoccupied, c)
	    end
	end
    end
    new(c0, target_lb, target_ub, peak, unoccupied, occupied, ms_wait, n_tries)
end


### EOF
