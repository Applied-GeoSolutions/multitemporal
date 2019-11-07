"""This module accepts two inputs and tries to find a correlation between them.

See test_1.py::test_two_sources.
"""

import numpy as np
cimport numpy as np
cimport cython
from libc.math cimport sqrt

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)

def get_nout(int nin, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
    return 4

def get_nyrout(int nyr, np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):
        return 1

def critical_t(int df):
    cdef np.ndarray[np.float64_t, ndim=1] c = np.array([
        12.706204736432095, 4.3026527299112747, 3.1824463052842629,
        2.7764451051977987, 2.5705818366147395, 2.4469118487916806,
        2.3646242510102993, 2.3060041350333704, 2.2621571627409915,
        2.2281388519649385, 2.2009851600829489, 2.1788128296634177,
        2.1603686564610127, 2.1447866879169273, 2.131449545559323,
        2.1199052992210112, 2.1098155778331806, 2.1009220402409601,
        2.093024054408263, 2.0859634472658364, 2.0796138447276622,
        2.0738730679040147, 2.0686576104190406, 2.0638985616280205,
        2.0595385527532941, 2.0555294386428709, 2.0518305164802833,
        2.0484071417952441, 2.045229642132703, 2.0422724563012373,
        2.0395134463964077, 2.0369333434601011, 2.0345152974493383,
        2.0322445093177182, 2.0301079282503425, 2.0280940009804502,
        2.0261924630291093, 2.0243941645751362, 2.022690911734728,
        2.0210753829953374, 2.0195409639828936, 2.018081697095881,
        2.0166921941428133, 2.0153675699129412, 2.0141033848332923,
        2.0128955952945886, 2.0117405104757546, 2.0106347546964454,
        2.0095752344892088, 2.0085591097152058, 2.0075837681558819,
        2.0066468031022113, 2.0057459935369497, 2.0048792865665228,
        2.004044781810181, 2.0032407174966975, 2.0024654580545986,
        2.0017174830120923, 2.0009953770482101, 2.0002978210582616,
        1.9996235841149779, 1.9989715162223112, 1.9983405417721956,
        1.9977296536259734, 1.9971379077520122, 1.9965644183594744,
        1.9960083534755055, 1.9954689309194018, 1.9949454146328136,
        1.9944371113297727, 1.993943367434504, 1.9934635662785827,
        1.9929971255321663, 1.9925434948468199, 1.9921021536898653,
        1.9916726093523487, 1.9912543951146038, 1.9908470685550519,
        1.9904502099893602, 1.9900634210283841, 1.9896863232444828,
        1.9893185569368186, 1.988959779987179, 1.9886096667986732,
        1.9882679073103775, 1.9879342060816718, 1.9876082814405769,
        1.9872898646909385, 1.9869786993737677, 1.9866745405784678,
        1.9863771543000648, 1.9860863168388934, 1.9858018142395026,
        1.9855234417658298, 1.9852510034099262, 1.9849843114317689,
        1.9847231859278831, 1.984467454426692, 1.9842169515086827,
        1.9839715184496334])
    if df > 1000:
        return 1.9623367052808787
    elif df > 100:
        return 1.983731002885281
    else:
        return <float>c[df]

def linearmodel(np.ndarray[np.float32_t, ndim=1] x not None,
                np.ndarray[np.float32_t, ndim=1] y not None,
                float missingval):
    cdef int nt = x.shape[0]
    cdef float sumx = 0.0
    cdef float sumy = 0.0
    cdef float sumxy = 0.0
    cdef float sumxx = 0.0
    cdef float sumyy = 0.0
    cdef float n = 0.0
    cdef float slope = missingval
    cdef float intercept = missingval
    cdef float corrcoef = missingval
    cdef float tstat = missingval
    cdef float denom1, denom2, denom3
    cdef int i
    for i in range(nt):
        if x[i] != missingval and y[i] != missingval:
            sumx = sumx + x[i]
            sumy = sumy + y[i]
            sumxy = sumxy + (x[i]*y[i])
            sumxx = sumxx + x[i]*x[i]
            sumyy = sumyy + y[i]*y[i]
            n = n + 1.0
    if n > 0.0:
        meanx = sumx/n
        meany = sumy/n
        denom1 = (sumxx - sumx*meanx)
        if denom1 != 0.0:
            slope = (sumxy - sumx*meany)/denom1
            intercept = meany - slope*meanx
            denom2 = sqrt((n*sumxx - sumx*sumx)*(n*sumyy - sumy*sumy))
            if denom2 != 0.0:
                corrcoef = (n*sumxy - sumx*sumy)/denom2
                denom3 = (1.0 - corrcoef*corrcoef)
                if denom3 != 0.0:
                    tstat = corrcoef*sqrt((n - 2.0)/denom3)

    return slope, intercept, corrcoef, tstat


def correlate(np.ndarray[np.float32_t, ndim=4, negative_indices=False] data not None,
              float missingval,
              np.ndarray[np.float32_t, ndim=1, negative_indices=False] params not None):

    cdef int nbd = data.shape[0]
    cdef int nfr = data.shape[1]
    cdef int nyr = data.shape[2]
    cdef int npx = data.shape[3]

    cdef int nout = get_nout(nfr, params)
    cdef int nyrout = get_nyrout(nyr, params)

    cdef np.ndarray[np.float32_t, ndim=1] x = np.zeros(nyr, dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=1] y = np.zeros(nyr, dtype='float32')
    cdef np.ndarray[np.float32_t, ndim=3] result = np.zeros(
        (nout,nyrout,npx), dtype='float32')

    # calculate correlation for this band of input data only
    cdef int iband = <int>params[0]

    cdef int i,j
    cdef long k
    cdef float tcrit, count

    for k in range(npx):
        count = 0.0
        for j in range(nyr):
            if data[0,iband,j,k] != missingval and data[1,iband,j,k] != missingval:
                x[j] = data[1,iband,j,k] # independent variable
                y[j] = data[0,iband,j,k] # dependent variable
                count = count + 1.0
            else:
                x[j] = missingval
                y[j] = missingval

        if count <= 2.0:
            tstat = missingval
        else:
            tcrit = critical_t(<int>(count - 2.0))
            slope, intercept, corrcoef, tstat = linearmodel(x, y, missingval)
            result[0,0,k] = slope
            result[1,0,k] = intercept
            result[2,0,k] = corrcoef

        result[3,0,k] = tstat

    return result
