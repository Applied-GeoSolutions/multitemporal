#!/usr/bin/env python

from __future__ import print_function
from __future__ import division
from builtins import map
from builtins import range
from past.utils import old_div
import os
from multiprocessing import Pool
import numpy as np
import sharedmem

from pdb import set_trace

NPROC = 5
N = 256
M = 16
W = 1024
MEM0 = None

def mem():
    tot_m, used_m, free_m = list(map(
        int, os.popen('free -t -m').readlines()[-1].split()[1:]
    ))
    return float(used_m)

def worker(job):
    global MEM0
    d = old_div(M,N)
    istart = job*d
    iend = job*d + d
    print("starting", job, istart, iend, mem() - MEM0)
    for i in range(W):
        for j in range(W):
            data[istart:iend, :, :] = istart
    print("done", job, istart, iend, mem() - MEM0)
    return 1

data = None
def main():
    global MEM0
    global data
    MEM0 = mem()
    print("initial:", mem() - MEM0)
    data = sharedmem.empty((M,W,W), dtype='f4')
    jobs = list(range(N))
    print(mem() - MEM0)
    pool = Pool(processes=NPROC)
    results = pool.map(worker, jobs)
    print(mem() - MEM0)

if __name__ == "__main__":

    main()
    
    
    
