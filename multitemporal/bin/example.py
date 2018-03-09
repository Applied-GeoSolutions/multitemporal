#!/usr/bin/env python

from multiprocessing import Pool

import numpy as np

#import sharedmem


def worker(job):

    i = job[0]
    x = job[1]
    
    y = x*10
    
    return i,x,y


#jobs = [(0, 23.), (1, 56.), (2, 99.)]

jobs = []
for i in range(100):
    jobs.append((i, np.random.random()))

pool = Pool(processes=3)
results = pool.map(worker, jobs)

print results




