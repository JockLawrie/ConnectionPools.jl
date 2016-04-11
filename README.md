# ConnectionPools

[![Build Status](https://travis-ci.org/JockLawrie/ConnectionPools.jl.svg?branch=master)](https://travis-ci.org/JockLawrie/ConnectionPools.jl)


### Introduction
Loosely speaking, a connection pool is a set of connections to a given database. Its purpose is to re-use existing connections rather than create a new connection every time data must be fetched from the database. Thus connection pools are useful for reducing latency in applications that require database access.


### Functionality
- Set target lower and (finite) upper bounds on the number of connections in the pool under typical usage.
- Set a (finite) peak number of connections, the absolute maximum number of connections that can be made.
- Reset the target and peak numbers as desired (the peak is constrained to be at least as large as the target upper bound).
- When requesting a connection from the pool:
    - If the target upper bound has not been reached, get a connection from the `unoccupied` set if there is one, otherwise create a new one.
    - If the target upper bound has been reached:
        - If the peak number has not been reached, create a new connection (and manually delete it when finished).
        - If the peak number has been reached, wait `ms_wait` milliseconds and try again to acquire a connection.
        - Try a maximum of `n_tries` times to acquire a connection from the pool.
        - If all attempts to acquire a connection fail, return the connection pool's connection prototype (a disconnected instance of the connection used to instantiate the connection pool).

__Note:__ ConnectionPools.jl has only been tested with Redis so far. To add support for a new database, simply define a `new_connection(c)` method for your database type, see `src/new_connections` for details and examples.


### Redis example
```julia
using ConnectionPools
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
get(c1, "foo") == "bar"     # true
get(c2, "foo") == "bar"     # true
c3 == 0                     # true because a maximum of 2 connections is allowed

set_target_upper!(cp, 3)    # Also sets peak to 3 because the constraint target_ub <= peak is enforced
c3 = get_connection!(cp)
c3 == 0                     # false because a 3rd connection is now allowed
get(c3, "foo") == "bar"     # true

c4 = get_connection!(cp)
c4 == 0                     # true because a maximum of 3 connections is allowed
set_peak!(cp, 4)            # Increase peak from 3 to 4, leaving target upper bound at 3
c4 = get_connection!(cp)
c4 == 0                     # false because a 4th connection is now allowed
get(c4, "foo") == "bar"     # true

# Clean up
free!(cp, c4)               # Deletes c4 from cp because 4 is more than the target upper bound
free!(cp, c3)               # Moves c3 from occupied to unoccupied
free!(cp, c2)
free!(cp, c1)
delete!(cp)                 # Delete all connections from the pool and set target bounds and peak to 0. Requires get_n_occupied(cp) == 0.
```

Note that `ConnectionPool(RedisConnection(), 0, 0, target_ub, 0, 0)` results in creating a new connection each time data must be fetched, then deleting the connection (after the data is fetched) by calling `free!`. Since failure to call `free!` will cause the number of connections to increase without bound, a finite number is required for `target_ub`.

### API
The `ConnectionPool` type has the following structure and methods:
```julia
type ConnectionPool
    connection_prototype    # A disconnected instance of the connection
    target_lb::Int64        # Lower bound of target number of connections in the pool
    target_ub::Int64        # Upper bound of target number of connections in the pool
    peak::Int64             # Peak number of connections in the pool 
    unoccupied::Set         # The set of connections in the pool that are not being used
    occupied::Set           # The set of connections in the pool that are being used
    ms_wait::Int64          # If all connections are busy, how long to wait (ms) before trying to connect again
    n_tries::Int64          # How many times to retry acquiring a connection
end

# Constructor
# On creation, target_lb connections will be created
cp = ConnectionPool(connection, target_lb, target_ub, peak, ms_wait, n_tries)

# Getters
c = get_connection!(cp)     # Gets a connection from the pool if one is available, else returns cp.connection_prototype
get_n_connections(cp)       # Number of connections, occupied or not
get_n_unoccupied(cp)
get_n_occupied(cp)
get_target_lower(cp)
get_target_upper(cp)
get_peak(cp)
get_wait(cp)
get_n_tries(cp)

# Setters
# An error is raised if cp.target_lb <= cp.target_ub <= cp.peak is not satisfied.
set_target_lower!(cp, n)       # Adjusts cp.unoccupied accordingly if necessary
set_target_upper!(cp, n)       # Adjusts cp.unoccupied accordingly if necessary
set_peak!(cp, n)
set_wait!(cp, n)
set_n_tries!(cp, n)

# Cleaning up
free!(cp, c)                # Sets the connection c to unoccupied if target upper is not exceeded, otherwise removes it from the pool
delete!(cp)                 # Disconnects and removes all connections in the pool and sets target_ub and peak to 0
```

### Todo
1. Support connections to other databases on an as-needed basis.
