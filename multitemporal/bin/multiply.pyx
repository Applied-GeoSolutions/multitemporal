import numpy as np
cimport numpy as np
cimport cython

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return 1

def get_nyrout(int nyr, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return nyr

#
# Apply a mask or just multiply two matching arrays
#

def validmask(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
                     float missingval,
                     np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef int nfr = data.shape[0]
    cdef int nyr = data.shape[1]
    cdef unsigned int npx = data.shape[2]

    cdef float thresh = 0.0
    cdef int mode = 0
    cdef int minframe = 1
    cdef int maxframe = nfr
    if params.shape[0] > 0:
        thresh = params[0]
    if params.shape[0] > 1:
        mode = <int>params[1]
    if params.shape[0] > 2:
        minframe = <int>params[2]
        maxframe = <int>params[3]

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((1,nyr,npx), dtype='float32')

    cdef int i,j
    cdef unsigned int k
    cdef float count1, count2

    # mode=0: fraction, annual
    # mode=1: number, annual
    # mode=2: fraction, combined years
    # mode=3: number, combined years

    for k in range(npx):

        for j in range(nyr):
            count1 = 0.0
            count2 = 0.0
            for i in range(nfr):
                if i+1 < minframe or i+1 > maxframe:
                    continue
                count1 = count1 + 1.0
                if data[i,j,k] != missingval:
                    count2 = count2 + 1.0
            result[0,j,k] = 0

            if mode == 0 or mode == 2:
                if count2/count1 > thresh:
                    result[0,j,k] = 1
            elif mode == 1 or mode == 3:
                if count2 > thresh:
                    result[0,j,k] = 1

        if mode == 2 or mode == 3:
            for j in range(nyr):
                result[0,j,k] = result[0,0,k] * result[0,j,k]

    return result
