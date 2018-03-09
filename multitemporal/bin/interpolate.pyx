import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return nin

def interpolate(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
                float missingval,
                np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned long npx = data.shape[2]

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((nfr,nyr,npx), dtype='float32')

    cdef unsigned int ntime = nfr*nyr
    cdef unsigned int i, j, n, m
    cdef unsigned long k
    cdef float x0, x1, y0, y1

    cdef np.ndarray[np.float32_t, ndim=2] interpval = np.zeros((2,ntime), dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=2] interppos = np.zeros((2,ntime), dtype='float32')

    for k in range(npx):

        if data[0,0,k] == missingval:
            interpval[0,0] = missingval
        else:
            interpval[0,0] = data[0,0,k]
            interppos[0,0] = 0.0
        
        if data[nfr-1,nyr-1,k] == missingval:
            interpval[1,ntime-1] = missingval
        else:
            interpval[1,ntime-1] = data[nfr-1,nyr-1,k]
            interppos[1,ntime-1] = <float>(ntime-1)

        for n in range(1,ntime):

            # back looking
            i = n % nfr
            j = n / nfr
            if data[i,j,k] != missingval:
                interpval[0,n] = data[i,j,k]
                interppos[0,n] = <float>n
            else:
                interpval[0,n] = interpval[0,n-1]
                interppos[0,n] = interppos[0,n-1]

            # forward looking
            m = ntime - n - 1
            i = m % nfr
            j = m / nfr
            if data[i,j,k] != missingval:
                interpval[1,m] = data[i,j,k]
                interppos[1,m] = <float>m
            else:
                interpval[1,m] = interpval[1,m+1]
                interppos[1,m] = interppos[1,m+1]

        for n in range(ntime):
            i = n % nfr
            j = n / nfr
            if data[i,j,k] == missingval:
                y0 = interpval[0,n]
                y1 = interpval[1,n]
                if y0 == missingval:
                    result[i,j,k] = y1
                elif y1 == missingval:
                    result[i,j,k] = y0
                else:
                    x0 = interppos[0,n]
                    x1 = interppos[1,n]
                    result[i,j,k] = y0 + (y1 - y0)*(<float>n - x0)/(x1 - x0)
            else:
                result[i,j,k] = data[i,j,k]

    return result
