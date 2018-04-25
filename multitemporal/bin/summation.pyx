import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return 2
    
def summation(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
              float missingval,
              np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned int npx = data.shape[2]

    cdef float thresh = params[0]
    cdef int minframe = 1
    cdef int maxframe = nfr
    if params.shape[0] > 2:
        minframe = <int>params[1]
        maxframe = <int>params[2]

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((2,nyr,npx), dtype='float32')

    cdef unsigned int i,j,k

    for k in range(npx):
        for j in range(nyr):
            for i in range(nfr):
                if i+1 < minframe or i+1 > maxframe:
                    continue
                if data[i,j,k] != missingval and data[i,j,k] > thresh:
                    result[0,j,k] = result[0,j,k] + data[i,j,k]
                    result[1,j,k] = result[1,j,k] + 1.0
            if result[1,j,k] == 0.0:
                result[0,j,k] = missingval
                result[1,j,k] = 0.0

    return result
