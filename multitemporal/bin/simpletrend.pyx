import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)


def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return 2


def simpletrend(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
                float missingval,
	            np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    # minval - data below this value are considered missing
    # maxval - data above this value are considered missing
    # minframe - data before this time are ignored
    # maxframe - data after this time are ignored

    cdef float minval  = params[0]
    cdef float maxval = params[1]
    cdef int minframe = <int>params[2]
    cdef int maxframe = <int>params[3]

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned int npx = data.shape[2]

    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((2,nyr,npx), dtype='float32')

    cdef unsigned int i,j,k

    cdef float x0, y0, dx, dy
    cdef float slope, count

    for k in range(npx):

        for j in range(nyr):

            x0 = missingval
            y0 = missingval
            slope = 0.0
            count = 0.0
     
            for i in range(nfr):

                if i+1 >= minframe and i+1 <= maxframe \
                and data[i,j,k] > minval and data[i,j,k] < maxval:
    
                    if x0 == missingval:
                        x0 = <float>i
                        y0 = data[i,j,k]               
                    
                    else:
                        dx = <float>i - x0
                        dy = data[i,j,k] - y0
                        slope = slope + (dy/dx)
                        count = count + 1.0
    
            # generate output
            if count > 0.0:
                result[0,j,k] = slope/count
                result[1,j,k] = count
            else:
                result[0,j,k] = missingval
                result[1,j,k] = missingval
 
    return result
