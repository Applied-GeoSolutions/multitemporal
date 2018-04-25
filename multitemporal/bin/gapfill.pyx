import numpy as np
cimport numpy as np
cimport cython
    
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return nin

def gapfill(np.ndarray[np.float32_t, ndim=3, negative_indices=False] data not None,
            float missingval,
            np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    # minval - data below this value are considered missing
    # maxval - data above this value are considered missing
    # maxgapfrac - set result to missing if more than this fraction are missing

    cdef float minval  = params[0]
    cdef float maxval = params[1]
    cdef float maxgapfrac = params[2]

    cdef unsigned int nfr = data.shape[0]
    cdef unsigned int nyr = data.shape[1]
    cdef unsigned long npx = data.shape[2]

    cdef np.ndarray[np.float32_t, ndim=1] cycle = np.zeros(nfr, dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=3] neighbors = np.zeros((nfr,nyr,2), dtype='float32')
    cdef np.ndarray[np.int16_t, ndim=2] state = np.ones((nfr,nyr), dtype='int16')
    
    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros((nfr,nyr,npx), dtype='float32')

    cdef unsigned int count, nmissing, maxmissing
    cdef unsigned int ntime = nfr*nyr
    cdef unsigned int i,j,n,m
    cdef unsigned long k

    cdef np.ndarray[np.float32_t, ndim=2] interpval = np.zeros((2,ntime), dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=2] interppos = np.zeros((2,ntime), dtype='float32')

    cdef float x0, x1, y0, y1
    cdef float height, annmean
    cdef int start, end

    for k in range(npx):
        # initialize state
        for i in range(nfr):
            for j in range(nyr):
                if data[i,j,k] > minval and data[i,j,k] < maxval:
                    # valid
                    state[i,j] = 0
                    result[i,j,k] = data[i,j,k]
                else:
                    # not valid
                    state[i,j] = 1
                    result[i,j,k] = 0

        # get the mean annual cycle
        for i in range(nfr):
            cycle[i] = 0.0
            count = 0
            for j in range(nyr):            
                # allow all valid obs to factor into annual mean
                if state[i,j] == 0:
                    cycle[i] = cycle[i] + data[i,j,k]
                    count = count + 1
            # require at least one point for mean
            if count > 0:
                cycle[i] = cycle[i] / <float>count
            else:
                cycle[i] = missingval

        # calculate adjacent composite neighbors
        for n in range(ntime):
            i = n % nfr
            j = n / nfr
            neighbors[i,j,0] = missingval
            # only calculate neighbors if current obs is invalid
            if state[i,j] == 1:
                # check if previous and next composite are in bounds
                if n >= 1 and n < (ntime-1):
                    im = (n-1) % nfr
                    ip = (n+1) % nfr
                    jm = (n-1) / nfr
                    jp = (n+1) / nfr
                    # mean of previous and next composite
                    if state[im,jm] != 1 and state[ip,jp] != 1:
                        neighbors[i,j,0] = (data[im,jm,k] + data[ip,jp,k])/2.0

        # calculate adjacent years neighbors
        for n in range(ntime):
            i = n % nfr
            j = n / nfr
            neighbors[i,j,1] = missingval
            # only calculate neighbors if current obs is invalid
            if state[i,j] == 1:
                # check if previous and next year are in bounds
                if j >= 1 and j < (nyr-1):
                    jm = j - 1
                    jp = j + 1
                    # last year, same composite
                    if state[i,jm] != 1 and state[i,jp] != 1:
                        neighbors[i,j,1] = (data[i,jm,k] + data[i,jp,k])/2.0

        # do gap filling
        nmissing = 0
        for i in range(nfr):
            for j in range(nyr):
                # consider only missing pixels
                if state[i,j] == 1:
                    count = 0
                    # use composite neighbors
                    if neighbors[i,j,0] != missingval:
                        result[i,j,k] += neighbors[i,j,0]
                        count += 1
                    # use years neighbors
                    if neighbors[i,j,1] != missingval:
                        result[i,j,k] += neighbors[i,j,1]
                        count += 1
                    # long term mean
                    if cycle[i] != missingval:
                        result[i,j,k] += cycle[i]
                        count += 1
                    # fill
                    if count > 0:
                        result[i,j,k] /= <float>count
                        state[i,j] = 2
                    # unfilled
                    else:
                        nmissing = nmissing + 1
                        # state remains 1

        # state is 0-valid, 1-missing, 2-filled
        # three cases: too many missing, some missing, none missing

        maxmissing = <int>(maxgapfrac * <float>ntime)
        if nmissing >= maxmissing:
            # too many missing, set all for this pixel to missing
            for n in range(ntime):
                i = n % nfr
                j = n / nfr
                result[i,j,k] = missingval
                state[i,j] = 1
            nmissing = ntime

        elif nmissing > 0 and nmissing < maxmissing:
            # some still missing, perform desperation gap filling
    
            if state[0,0] == 1:
                interpval[0,0] = missingval
            else:
                interpval[0,0] = result[0,0,k]
                interppos[0,0] = 0.0

            if state[nfr-1,nyr-1] == 1:
                interpval[1,ntime-1] = missingval
            else:
                interpval[1,ntime-1] = result[nfr-1,nyr-1,k]
                interppos[1,ntime-1] = <float>(ntime-1)

            for n in range(1,ntime):

                # back looking
                i = n % nfr
                j = n / nfr
                if state[i,j] != 1:
                    interpval[0,n] = result[i,j,k]
                    interppos[0,n] = <float>n
                else:
                    interpval[0,n] = interpval[0,n-1]
                    interppos[0,n] = interppos[0,n-1]

                # forward looking
                m = ntime - n - 1
                i = m % nfr
                j = m / nfr
                if state[i,j] != 1:
                    interpval[1,m] = result[i,j,k]
                    interppos[1,m] = <float>m
                else:
                    interpval[1,m] = interpval[1,m+1]
                    interppos[1,m] = interppos[1,m+1]

            for n in range(ntime):
                i = n % nfr
                j = n / nfr
                if state[i,j] == 1:
                    y0 = interpval[0,n]
                    y1 = interpval[1,n]
                    if y0 == missingval:
                        result[i,j,k] = y1
                        state[i,j] = 2
                    elif y1 == missingval:
                        result[i,j,k] = y0
                        state[i,j] = 2
                    else:
                        x0 = interppos[0,n]
                        x1 = interppos[1,n]
                        result[i,j,k] = y0 + (y1 - y0)*(<float>n - x0)/(x1 - x0)
                        state[i,j] = 2

    return result
