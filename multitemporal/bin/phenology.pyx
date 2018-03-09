import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return 5

# Outputs
# 1 Mean value above threshold
# 2 Max value
# 3 First time over threshold
# 4 Time of maximum value
# 5 Last time over threshold

def phenology(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
              float missingval,
              np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    # threshold - a critical value that data are compared with
    # minval - data below this value are considered missing
    # maxval - data above this value are considered missing
    # minframe - data before this time are ignored
    # maxframe - data after this time are ignored

    cdef float thresh = params[0]
    cdef float minval = params[1]
    cdef float maxval = params[2]
    cdef int minframe = <int>params[3]
    cdef int maxframe = <int>params[4]

    cdef int nfr = data.shape[0]
    cdef int nyr = data.shape[1]
    cdef int npx = data.shape[2]

    cdef int nout = get_nout(nfr, params)
    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((nout,nyr,npx), dtype='float32')

    cdef int count, nmissing
    cdef int ntime = nfr*nyr
    cdef int i,j,k,n,m

    cdef float x0, x1, y0, y1
    cdef float height, annmean
    cdef int start, end, argmax

    for k in range(npx):
        for j in range(nyr):

            start = 0
            end = nfr
            height = -1.E99
            annmean = 0.0
            count = 0
            argmax = 0

            for i in range(nfr):

                if i+1 < minframe or i+1 > maxframe:
                    continue

                if data[i,j,k] > thresh:

                    if start == 0:
                        start = i + 1
     
                    if data[i,j,k] - thresh > height:
                        height = data[i,j,k] - thresh
                        argmax = i

                    end = i
                    annmean += data[i,j,k]
                    count += 1

            # generate output
            if count > 0:
                result[0,j,k] = annmean/<float>count
                result[1,j,k] = height
                result[2,j,k] = <float>start
                result[3,j,k] = <float>argmax
                result[4,j,k] = <float>end
            else:
                result[0,j,k] = missingval
                result[1,j,k] = missingval
                result[2,j,k] = missingval
                result[3,j,k] = missingval
                result[4,j,k] = missingval

    return result
