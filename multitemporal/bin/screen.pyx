import numpy as np
cimport numpy as np
cimport cython

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return nin

def screen(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
           float missingval,
           np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned long npx = data.shape[2]

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((nfr,nyr,npx), dtype='float32')

    cdef unsigned int i, j
    cdef unsigned long k

    cdef float min1 = params[0]
    cdef float max1 = params[1]

    for k in range(npx):
        for j in range(nyr):
            for i in range(nfr):
                result[i,j,k] = data[i,j,k]
                if data[i,j,k] != missingval:
                    if data[i,j,k] < min1 or data[i,j,k] > max1:
                        result[i,j,k] = missingval
    return result
