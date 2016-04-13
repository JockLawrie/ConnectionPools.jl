module ConnectionPools

import Base.delete!

export ConnectionPool,
    # Getters
       get_connection!,
       get_n_connections,
       get_n_unoccupied,
       get_n_occupied,
       get_target,
       get_peak,
       get_wait,
       get_n_tries,
    # Setters
       set_target!,
       set_peak!,
       set_wait!,
       set_n_tries!,
    # Cleaning up
       release!,
       delete!


include("constructors.jl")
include("getters.jl")
include("setters.jl")
include("cleanup.jl")

function new_connection end
function disconnect end

end # module
