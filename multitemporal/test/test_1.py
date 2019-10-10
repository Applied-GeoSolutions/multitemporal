from builtins import str
import os
import json

import pytest
from osgeo import gdal

from multitemporal import mt

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
#     mt.run(**args)
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


@pytest.mark.parametrize("nproc", [1, 2])
def test_passthrough(nproc, tmpdir):
    """Use the passthrough module as a way to test mt throughput."""
    # refactor out for additional tests and follow pattern in files:
    input_dir = os.path.join(data_dir(), 'input')
    output_bn = 'tpt_proj_passthrough.tif'
    expected_fp = os.path.join(data_dir(), 'expected', output_bn)
    actual_fp = str(tmpdir.join(output_bn))

    mt.run(projname='tpt_proj', projdir=input_dir, outdir=str(tmpdir), nproc=nproc,
           **test_passthrough_args)

    actual = gdal.Open(actual_fp).ReadAsArray()
    expected = gdal.Open(expected_fp).ReadAsArray()
    # both pytest & numpy have approximate-equality abilities if needed
    assert (expected == actual).all()

def test_find_band():
    """Check mt.find_band for normal case."""
    test_raster_fp = os.path.join(data_dir(), '2016004_LC8_ndvi-toa.tif')
    test_raster_fo = gdal.Open(test_raster_fp)
    expected_band_name = 'ndvi'
    actual_band_name = mt.find_band(test_raster_fo, expected_band_name).GetDescription()
    assert expected_band_name == actual_band_name
