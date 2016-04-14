# ConnectionPools

[![Build Status](https://travis-ci.org/JockLawrie/ConnectionPools.jl.svg?branch=master)](https://travis-ci.org/JockLawrie/ConnectionPools.jl)
[![Coverage Status](http://codecov.io/github/JockLawrie/ConnectionPools.jl/coverage.svg?branch=master)](http://codecov.io/github/JockLawrie/ConnectionPools.jl?branch=master)


### Introduction
Loosely speaking, a connection pool is a set of connections to a given database. Its purpose is to re-use existing connections rather than create a new connection every time data must be fetched from the database. Thus connection pools are useful for reducing latency in applications that require database access.


### Functionality
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


__Notes:__

1. ConnectionPools.jl has only been tested with Redis so far.
2. To add support for a new database, simply define methods for `new_connection(c)` and `disconnect(c)` for your database type. See `src/supported_databases/` for details and examples.
3. If `target_pool_size` is increased above `peak_size`, then `peak_size` is increased to the new value of `target_pool_size`. 
4. Similarly, if `peak_size` is decreased below `target_pool_size`, then `target_pool_size` is decreased to the new value of `peak_size`. 


### Redis example
```julia
using ConnectionPools
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
get(c1, "foo") == "bar"     # true
get(c2, "foo") == "bar"     # true
println(is_connected(c3))   # false because a maximum of 2 connections is allowed

# Increase target_ub
set_target!(cp, 3)          # Also sets peak_size to 3 because the constraint target_pool_size <= peak_size is enforced
c3 = get_connection!(cp)
println(is_connected(c3))   # true because a 3rd connection is now allowed
get(c3, "foo") == "bar"     # true

# Increase peak
c4 = get_connection!(cp)
println(is_connected(c4))   # false because a maximum of 3 connections is allowed
set_peak!(cp, 4)            # Increase peak_size from 3 to 4, leaving target_pool_size at 3
c4 = get_connection!(cp)
println(is_connected(c4))   # true because a 4th connection is now allowed
get(c4, "foo") == "bar"     # true

# Clean up
release!(cp, c4)            # Deletes c4 from cp because 4 is more than target_pool_size
release!(cp, c3)            # Moves c3 from occupied to unoccupied because target_pool_size equals 3 (so 3 connections are retained in the pool)
release!(cp, c2)
release!(cp, c1)
delete!(cp)                 # Delete all connections from the pool and set target_pool_size and peak_size to 0. Requires get_n_occupied(cp) == 0.
```

Note that `ConnectionPool(RedisConnection(), 0, peak_size, 0, 0)` results in creating a new connection each time data must be fetched. Be sure to manually delete the connection (after the data is fetched) by calling `release!`. Since failure to call `release!` will cause the number of connections to increase without bound, a finite number is required for `peak` (the constraint `target_pool_size <= peak_size` is automatically enforced, which ensures that `target_pool_size` is also finite).

### API
The `ConnectionPool` type has the following structure and methods:
```julia
type ConnectionPool
    connection_prototype       # A disconnected instance of the connection
    target_pool_size::Int64    # Target number of connections in the pool
    peak_size::Int64           # Peak number of connections in the pool 
    unoccupied::Set            # The set of connections in the pool that are not being used
    occupied::Set              # The set of connections in the pool that are being used
    ms_wait::Int64             # If all connections are busy, how long to wait (ms) before trying to connect again
    n_tries::Int64             # How many times to retry acquiring a connection
end

# Constructor
cp = ConnectionPool(connection, target_pool_size, peak_size, ms_wait, n_tries)

# Getters
c = get_connection!(cp)        # Gets a connection from the pool if one is available, else returns cp.connection_prototype
get_n_connections(cp)          # Number of connections, occupied or not
get_n_unoccupied(cp)
get_n_occupied(cp)
get_target(cp)
get_peak(cp)
get_wait(cp)
get_n_tries(cp)

# Setters
set_target!(cp, n)
set_peak!(cp, n)
set_wait!(cp, n)
set_n_tries!(cp, n)

# Cleaning up
release!(cp, c)             # Sets the connection c to unoccupied if target_pool_size is not exceeded, otherwise removes it from the pool
delete!(cp)                 # Disconnects all connections and removes them from the pool and sets target_pool_size and peak_size to 0
```

### Todo
1. Support connections to other databases on an as-needed basis.
