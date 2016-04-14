using ConnectionPools
using Base.Test


using Redis

# Create some test data
c = RedisConnection()
set(c, "foo", "bar")
disconnect(c)


# Create a connection pool of RedisConnections with a target of 2 connections and a peak of 2 connections.
# Try to acquire a connection up to 10 times, waiting 500ms between each try.
cp = ConnectionPool(RedisConnection(), 2, 2, 500, 10)
c1 = get_connection!(cp)
c2 = get_connection!(cp)
c3 = get_connection!(cp)
@test get(c1, "foo") == "bar"
@test get(c2, "foo") == "bar"
@test !is_connected(c3)         # Because a maximum of 2 connections is allowed

set_target!(cp, 3)              # Also sets peak to 3 because the constraint target_pool_size <= peak_size is enforced
c3 = get_connection!(cp)        # Create a 3rd connection and push it to cp.unoccupied
release!(cp, c3)
c3 = get_connection!(cp)        # Acquire a 3rd connection from cp.unoccupied
@test is_connected(c3)          # Because a 3rd connection is now allowed
@test get(c3, "foo") == "bar"

c4 = get_connection!(cp)
@test !is_connected(c4)         # Because a maximum of 3 connections is allowed
set_peak!(cp, 4)                # Increase peak_size from 3 to 4, leaving target_pool_size at 3
release!(cp, c3)                # Make c3 available (push c3 to cp.unoccupied)
c4 = get_connection!(cp)        # c4 = the old c3 (get c3 from cp.unoccupied)
@test is_connected(c4)          # Because a 4th connection is now allowed
@test get(c4, "foo") == "bar"

# set wait and n_tries
set_wait!(cp, 200)
set_n_tries!(cp, 5)
@test get_wait(cp) == 200
@test get_n_tries(cp) == 5

# Clean up
set_target!(cp, 2)
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 3
@test get_n_unoccupied(cp) == 0
release!(cp, c4)                       # Removes c4 from the pool because target_pool_size is 2
@test get_n_connections(cp) == 2
@test get_n_occupied(cp) == 2
@test get_n_unoccupied(cp) == 0
release!(cp, c2)                       # Moves c2 from occupied to unoccupied
@test get_n_connections(cp) == 2
@test get_n_occupied(cp) == 1
@test get_n_unoccupied(cp) == 1
release!(cp, c1)                       # Moves c1 from occupied to unoccupied
@test get_n_connections(cp) == 2
@test get_n_occupied(cp) == 0
@test get_n_unoccupied(cp) == 2
delete!(cp)                            # Disconnect all connections and remove the from the pool, and set target and peak to 0. Requires get_n_occupied(cp) == 0.
@test get_n_connections(cp) == 0

#=
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 2
@test get_n_unoccupied(cp) == 1
release!(cp, c2)
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 1
@test get_n_unoccupied(cp) == 2
release!(cp, c1)
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 0
@test get_n_unoccupied(cp) == 3
delete!(cp)                            # Disconnect all connections and remove the from the pool, and set target and peak to 0. Requires get_n_occupied(cp) == 0.
@test get_n_connections(cp) == 0
=#

# Delete test data
c = RedisConnection()
del(c, "foo")
disconnect(c)


###################
### Unsupported connection type
@test_throws ErrorException ConnectionPool("bogus_connection", 2, 2, 500, 10)

# EOF
