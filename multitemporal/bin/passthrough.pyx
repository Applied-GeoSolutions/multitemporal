import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    """Return the expected number of time periods (each is a year).

    This is based on the input number of time periods and the params of the
    operation.
    """
    return nin

# impossible to specify an unknown number of array dimensions at compile time:
#                          vvvvvv
# np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None
def passthrough(data not None, ignored_missing_out, ignored_params):
    """Identity function as a multitemporal module.

    Useful for testing and for using input data as output data.
    """
    return data
