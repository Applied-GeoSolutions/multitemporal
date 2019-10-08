import os
import json

import pytest
from osgeo import gdal

from multitemporal.mt import run

CWD = os.path.dirname(__file__)
TESTDATA = os.path.join(CWD, 'test1')
TESTCONF = os.path.join(CWD, 'test_correlate.json')


# for some reason pytest.mark.skip isn't working:
# @pytest.mark.skip(reason='no worky due to neglect it seems')
# def test_correlate():
#     if not os.path.exists(TESTDATA):
#         os.system('tar xfz {}.tgz -C {}'.format(TESTDATA, os.path.split(TESTDATA)[0]))
#     args = json.loads(open(TESTCONF).read())
#     args['projname'] = 'test1cmp'
#     args['projdir'] = TESTDATA
#     args['outdir'] = args['projdir'] + 'out'
#     run(**args)
#     outfile1 = os.path.join(args['outdir'], 'test1_correlate.tif')
#     outfile1cmp = os.path.join(args['outdir'], 'test1cmp_correlate.tif')
#     x1 = gdal.Open(outfile1).ReadAsArray()
#     x1cmp = gdal.Open(outfile1cmp).ReadAsArray()
#     assert (x1 - x1cmp).sum() < 0.0001


def test_passthrough():
    """Use the passthrough module as a way to test mt throughput."""
    TESTDATA = os.path.join(CWD, 'test1')
    TESTCONF = os.path.join(CWD, 'test_passthrough.json')
    if not os.path.exists(TESTDATA):
        os.system('tar xfz {}.tgz -C {}'.format(TESTDATA, os.path.split(TESTDATA)[0]))
    args = json.loads(open(TESTCONF).read())
    # ./multitemporal/test/test1out/test1cmp_passthrough_2014.tif
    # ./multitemporal/test/test1out/test1cmp_passthrough_2015.tif
    # ./multitemporal/test/test1out/test1cmp_passthrough_2016.tif
    args['projname'] = 'test1cmp'
    args['projdir'] = TESTDATA
    args['outdir'] = args['projdir'] + 'out'
    run(**args)
    outfile1 = os.path.join(args['outdir'], 'test1_passthrough.tif')
    outfile1cmp = os.path.join(args['outdir'], 'test1cmp_passthrough.tif')
    x1 = gdal.Open(outfile1).ReadAsArray()
    x1cmp = gdal.Open(outfile1cmp).ReadAsArray()
    assert (x1 - x1cmp).sum() < 0.0001
