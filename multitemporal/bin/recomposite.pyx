import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)


def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return params[0]


def recomposite(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
                float missingval,
                np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned int npx = data.shape[2]

    cdef int nfr1 = <int>params[0]
    cdef float fac = <float>nfr/<float>nfr1

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((nfr1,nyr,npx), dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=1] count = np.zeros(nfr1, dtype='float32')
    
    cdef unsigned int i,j,k
    cdef int i1

    for k in range(npx):
        for j in range(nyr):
            for i1 in range(nfr1):
                count[i1] = 0.0

            for i in range(nfr):
                if data[i, j, k] != missingval:
                    i1 = <int>(i/fac)
                    result[i1,j,k] = result[i1,j,k] + data[i,j,k]
                    count[i1] = count[i1] + 1.0

            for i1 in range(nfr1):
                if count[i1] > 0.0:
                    result[i1,j,k] = result[i1,j,k]/count[i1]
                else:
                    result[i1,j,k] = missingval
    
    return result
