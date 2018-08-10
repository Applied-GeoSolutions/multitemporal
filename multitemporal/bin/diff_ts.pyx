import numpy as np
cimport numpy as np
cimport cython
from libc.math cimport sqrt
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

##
## this module calculates a differenced time series
## assumes input is a regular time series
##

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return nin


def diff_ts(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
               float missingval,
               np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef int nfr = data.shape[0]
    cdef int nyr = data.shape[1]
    cdef int npx = data.shape[2]

    cdef int nout = get_nout(nfr, params)
    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros(
        (nout,nyr,npx), dtype='float32')

    cdef int i,j,k
    cdef float diff, count
    
    for k in range(npx):
        for j in range(nyr):
            result[0,j,k] = missingval
            for i in range(nfr-1):
                if data[i,j,k] != missingval and data[i+1,j,k] != missingval:
                    result[i+1,j,k] = data[i+1,j,k] - data[i,j,k]
                else:
                    result[i+1,j,k] = missingval
    return result
