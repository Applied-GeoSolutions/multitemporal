import os
import json
from multitemporal.mt import run
from osgeo import gdal

CWD = os.path.dirname(__file__)
TESTDATA = os.path.join(CWD, 'test1')
TESTCONF = os.path.join(CWD, 'test1.json')

def test():
    if not os.path.exists(TESTDATA):
        print "unpacking {}".format(TESTDATA)
        os.system('tar xvfz {}.tgz -C {}'.format(TESTDATA, os.path.split(TESTDATA)[0]))
    args = json.loads(open(TESTCONF).read())
    args['projname'] = 'test1cmp'
    args['projdir'] = TESTDATA
    args['outdir'] = args['projdir'] + 'out'
    run(**args)
    outfile1 = os.path.join(args['outdir'], 'test1_correlate.tif')
    outfile1cmp = os.path.join(args['outdir'], 'test1cmp_correlate.tif')
    x1 = gdal.Open(outfile1).ReadAsArray()
    x1cmp = gdal.Open(outfile1cmp).ReadAsArray()
    assert (x1 - x1cmp).sum() < 0.0001
    print "pass"
