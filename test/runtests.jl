using ConnectionPools
using Base.Test


using Redis

# Create some test data
c = RedisConnection()
set(c, "foo", "bar")
disconnect(c)


# Create a connection pool of RedisConnections with a target range of [0, 2] connections and a peak of 2 connections.
# Try to acquire a connection up to 10 times, waiting 500ms between each try.
cp = ConnectionPool(RedisConnection(), 0, 2, 2, 500, 10)
c1 = get_connection!(cp)
c2 = get_connection!(cp)
c3 = get_connection!(cp)
@test get(c1, "foo") == "bar"
@test get(c2, "foo") == "bar"
@test !is_connected(c3)         # Because a maximum of 2 connections is allowed

set_target_upper!(cp, 3)        # Also sets peak to 3 because the constraint target_ub <= peak is enforced
c3 = get_connection!(cp)
@test is_connected(c3)          # Because a 3rd connection is now allowed
@test get(c3, "foo") == "bar"

c4 = get_connection!(cp)
@test !is_connected(c4)         # Because a maximum of 3 connections is allowed
set_peak!(cp, 4)                # Increase peak from 3 to 4, leaving target upper bound at 3
c4 = get_connection!(cp)
@test is_connected(c4)          # Because a 4th connection is now allowed
@test get(c4, "foo") == "bar"

# set wait and n_tries
set_wait!(cp, 200)
set_n_tries!(cp, 5)
@test get_wait(cp) == 200
@test get_n_tries(cp) == 5

# Clean up
@test get_n_connections(cp) == 4
free!(cp, c4)                       # Deletes c4 from cp because 4 is more than the target upper bound
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 3
@test get_n_unoccupied(cp) == 0
free!(cp, c3)                       # Moves c3 from occupied to unoccupied
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 2
@test get_n_unoccupied(cp) == 1
free!(cp, c2)
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 1
@test get_n_unoccupied(cp) == 2
free!(cp, c1)
@test get_n_connections(cp) == 3
@test get_n_occupied(cp) == 0
@test get_n_unoccupied(cp) == 3
delete!(cp)                         # Delete all connections from the pool and set target bounds and peak to 0. Requires get_n_occupied(cp) == 0.
@test get_n_connections(cp) == 0


# Delete test data
c = RedisConnection()
del(c, "foo")
disconnect(c)


# EOF
