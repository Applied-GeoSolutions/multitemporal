import os
import json

import pytest
from osgeo import gdal

from multitemporal.mt import run

def data_dir():
    return os.path.join(os.path.dirname(__file__), 'data')

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


test_passthrough_args = {
    'compthresh': 0.01, # so smaller dataset will work
    "dperframe": 1,
    "sources"  : [{"name": "ndvi", "regexp": "^(\\d{7})_L.._ndvi-toa.tif$", "bandnum": 1}],
    "steps"    : [{"module": "passthrough", "params": [], "inputs": ["ndvi"], "output": True}]}


def test_passthrough(tmpdir):
    """Use the passthrough module as a way to test mt throughput."""
    # refactor out for additional tests and follow pattern in files:
    input_dir = os.path.join(data_dir(), 'passthrough/input')
    output_bn = 'tpt_proj_passthrough.tif'
    expected_fp = os.path.join(data_dir(), 'passthrough/expected/', output_bn)
    actual_fp = str(tmpdir.join(output_bn))

    run(projname='tpt_proj', projdir=input_dir, outdir=str(tmpdir), **test_passthrough_args)

    actual = gdal.Open(actual_fp).ReadAsArray()
    expected = gdal.Open(expected_fp).ReadAsArray()
    # both pytest & numpy have approximate-equality abilities if needed
    assert (expected == actual).all()
