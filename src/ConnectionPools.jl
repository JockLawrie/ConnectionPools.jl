module ConnectionPools

import Base.delete!

export ConnectionPool,
    # Getters
       get_connection!,
       get_n_connections,
       get_n_unoccupied,
       get_n_occupied,
       get_target_lower,
       get_target_upper,
       get_peak,
       get_wait,
       get_n_tries,
    # Setters
       set_target_lower!,
       set_target_upper!,
       set_peak!,
       set_wait!,
       set_n_tries!,
    # Cleaning up
       free!,
       delete!


include("constructors.jl")
include("getters.jl")
include("setters.jl")
include("cleanup.jl")


function new_connection end
function disconnect end

end # module
