import argparse
from copy import deepcopy
import datetime
from functools import partial
import imp
import importlib
import json
from multiprocessing import Pool
import os
import re
import sys

import numpy as np
from osgeo import gdal
gdal.UseExceptions()

import sharedmem

from pdb import set_trace


# output will be a dict of shared memory arrays
OUTPUT = {}


def reglob(path, regexp):
    """ return paths in a directory matching a pattern """
    patt = re.compile(regexp)
    paths = [os.path.join(path,f) for f in os.listdir(path) if patt.search(f)]
    return paths

def write_raster(outfile, data, proj, geo, missing):
    gdal.GDT_UInt8 = gdal.GDT_Byte
    np_dtype = str(data.dtype)
    dtype = eval('gdal.GDT_' + np_dtype.title().replace('Ui','UI'))
    driver = gdal.GetDriverByName('GTiff')
    nb, ny, nx = data.shape
    tfh = driver.Create(outfile, nx, ny, nb, dtype, [])
    tfh.SetProjection(proj)
    tfh.SetGeoTransform(geo)
    for i in range(nb):
        tband = tfh.GetRasterBand(i+1)
        tband.SetNoDataValue(missing)
        tband.WriteArray(data[i,:,:].squeeze())
    del tfh


def find_band(fp, name):
    max_bands = fp.RasterCount
    for i in range(1, max_bands+1):
        b = fp.GetRasterBand(i)
        if name == b.GetDescription():
            return b
    raise Exception("No such band")


def worker(shared, job):

    iblk, istart, iend, blkhgt = job
    sources, steps, blkrow, width, missing_out, nfr = shared

    nb = len(sources)
    npx = width*blkhgt

    for ib, source in enumerate(sources):
        if ib == 0:
            nt = len(source['paths'])
            nyr = nt/nfr
            data = missing_out + np.zeros((nb, nfr, nyr, npx), dtype='float32')

        else:
            assert nt == len(source['paths'])

        for ipath, path in enumerate(source['paths']):
            if path == "":
                continue
            fp = gdal.Open(path)
            try:
                if 'bandname' in source:
                    band = find_band(fp, source['bandname'])
                else:
                    band = fp.GetRasterBand(source['bandnum'])
            except:
                continue
            values = band.ReadAsArray(0, iblk*blkrow, width, blkhgt).flatten()
            values = values.astype('float32')
            wgood = np.where(values != source['missing_in'])
            if len(wgood[0]) == 0:
                continue
            iyr = ipath / nfr
            ifr = ipath % nfr
            data[ib, ifr, iyr, wgood] = \
                source['offset'] + source['scale']*values[wgood]
            del fp

    sourcenames = [source['name'] for source in sources]
    results = {}

    for step in steps:

        if step['initial'] == True:
            bix = [sourcenames.index(si) for si in step['inputs']]
            d = data[bix,:,:,:]
        else:
            d = np.array([results[si] for si in step['inputs']])

        if d.shape[0] == 1:
            d = d.reshape(d.shape[1], nyr, npx)

        results[step['name']] = step['function'](d, missing_out, step['params'])
        if step.get('output', False):
            try:
                OUTPUT[step['name']][:, :, istart:iend] = results[step['name']]
            except Exception as e:
                print('Exception in step "{}"'.format(step['name']))
                raise e
    return str(job) + str(shared)


def run(projdir, outdir, projname, sources, steps,
        blkrow=10, compthresh=0.1, nproc=1, missing_out=-32768.,
        dperframe=1, ymd=False,
        **kwargs):
    global OUTPUT

    for k, source in enumerate(sources):

        paths = reglob(projdir, source['regexp'])
        if len(paths) == 0:
            print "there are no data paths for %s" % projdir
            return

        pathdict = {}
        years = set()
        doys = set()
        initialized = False

        for i, path in enumerate(paths):
            filename = os.path.split(path)[1]
            datestr = re.findall(source['regexp'], filename)[0]
            if not ymd:
                # default: YYYYDDD
                date = datetime.datetime.strptime(datestr, '%Y%j')
            else:
                # optional: YYYYMMDD
                date = datetime.datetime.strptime(datestr, '%Y%m%d')

            year = date.year
            doy = int(date.strftime('%j'))
            years.add(year)
            doys.add(doy)
            pathdict[(year, doy)] = path

            if not initialized:
                fp = gdal.Open(path)
                try:
                    if 'bandname' in source:
                        band = find_band(fp, source['bandname'])
                    else:
                        band = fp.GetRasterBand(source['bandnum'])
                except:
                    continue
                proj = fp.GetProjection()
                geo = fp.GetGeoTransform()
                width = band.XSize
                height = band.YSize
                if 'scale' not in source:
                    source['scale'] = band.GetScale() or 1.
                if 'offset' not in source:
                    source['offset'] = band.GetOffset() or 0.
                if 'missing_in' not in source:
                    source['missing_in'] = band.GetNoDataValue()
                if source['missing_in'] is None:
                    raise Exception, "There is no missing value"
                if k == 0:
                    proj_check = proj
                    geo_check = geo
                    width_check = width
                    height_check = height
                else:
                    GEO_TOLER = 0.0001
                    if proj_check != proj or width_check != width or height_check != height \
                       or (np.array([x[1]-x[0] for x in zip(geo, geo_check)]) > GEO_TOLER).any():
                        raise Exception, "Export contents do not match in size, projection,"\
                            "or geospatial properties"

                initialized = True

        firstyr = min(years)
        lastyr = max(years)
        nyr = lastyr - firstyr + 1
        if k == 0:
            firstyr_check = firstyr
            lastyr_check = lastyr
        else:
            if firstyr_check != firstyr or lastyr_check != lastyr:
                emsg = ("Export year ranges do not match: {}!={} or {}!={}"
                        .format(firstyr_check, firstyr, lastyr_check, lastyr))
                print('Nota bene:\n\t' + emsg + '\n   This may be OK')

        doys = np.arange(366/dperframe).astype('int') + 1
        nfr = len(doys)

        selpaths = []
        ncomplete = 0
        ntotal = 0

        for year in range(firstyr, lastyr+1):
            for doy in doys:
                try:
                    selpaths.append(pathdict[(year, doy)])
                    ncomplete += 1
                except Exception, e:
                    selpaths.append('')
                ntotal += 1

        source['paths'] = selpaths
        pctcomplete = float(ncomplete)/ntotal

        print "number of paths", len(selpaths)
        print "ncomplete, ntotal, pctcomplete, firstyr, lastyr",\
            ncomplete, ntotal, pctcomplete, firstyr, lastyr
        assert pctcomplete > compthresh,\
            "not enough valid data (%f < %f) percent" %\
            (pctcomplete, compthresh)

    # process the steps

    for step in steps:
        # make sure every step has a name
        # TODO: check for uniqeness
        step['name'] = step.get('name', str(step['module']))

    for step in steps:

        # get functions and parameters for each step
        if 'path' in step:
            mod_info = imp.find_module(step['module'], [step['path']])
            mod = imp.load_module(step['module'], *mod_info)
            step['function'] = getattr(mod, step['module'])
        else:
            mod = importlib.import_module('multitemporal.bin.' + step['module'])
            step['function'] = eval("mod." + step['module'])
        step['params'] = np.array(step['params']).astype('float32')
        step['initial'] = False

        # determine the number of inputs to this step
        if not isinstance(step['inputs'], list):
            step['inputs'] = [step['inputs']]
        for thisinput in step['inputs']:
            if thisinput in [source['name'] for source in sources]:
                thisnin = nfr
                step['initial'] = True
            else:
                parentstep = [s for s in steps if s['name']==thisinput][0]
                thisnin = parentstep['nout']
            if 'nin' in step:
                assert step['nin'] == thisnin, "Number of inputs do not match"
            else:
                step['nin'] = thisnin

        # set the number of outputs for each step
        step['nout'] = int(mod.get_nout(step['nin'], step['params']))
        try:
            step['nyrout'] = int(mod.get_nyrout(nyr, step['params']))
        except:
            step['nyrout'] = nyr
        if step.get('output', False):
            print "output", mod, (step['nout'], step['nyrout'], height*width)
            OUTPUT[step['name']] = sharedmem.empty(
                (step['nout'], step['nyrout'], height*width), dtype='f4')
            OUTPUT[step['name']][...] = missing_out

    nblocks = height / blkrow
    if height % blkrow == 0:
        lastblkrow = blkrow
    else:
        nblocks = nblocks + 1
        lastblkrow = height % blkrow

    # make something to hold selpaths and missing_in for each source
    shared = (sources, steps, blkrow, width, missing_out, nfr)

    # create and run the jobs
    jobs = []
    for iblk in range(nblocks):
        istart = iblk * blkrow * width
        if iblk == nblocks - 1:
            blkhgt = lastblkrow
        else:
            blkhgt = blkrow
        iend = istart + width*blkhgt
        jobs.append((iblk, istart, iend, blkhgt))
    func = partial(worker, shared)
    if nproc > 1:
        results = []
        num_tasks = len(jobs)
        pool = Pool(processes=nproc)
        prog=0
        for i, r in enumerate(pool.imap(func, jobs, 1)):
            pct = float(i) / num_tasks * 100
            if pct // 10 > prog:
                prog += 1
                print('mt {:0.02f} complete.\r'.format(pct))
            results.append(r)
    else:
        results = []
        for job in jobs:
            results.append(func(job))

    # write outputs
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    for s in steps:
        if s.get('output', False):
            nout = s['nout']
            nyrout = s['nyrout']
            OUTPUT[s['name']] = OUTPUT[s['name']].reshape(
                nout, nyrout, height, width)
            for i in range(nyrout):
                # all this to just make the file name
                items = [projname, s['name']]
                if nyrout > 1:
                    items.append(str(firstyr + i))
                prefix = "_".join(items)
                outname = prefix + ".tif"
                outpath = os.path.join(outdir, outname)
                outtype = s.get('output_type', OUTPUT[s['name']].dtype)
                print(("writing:", outpath, OUTPUT[s['name']].shape,
                       nout, height, width, 'as {}'.format(outtype)))
                write_raster(
                    outpath,
                    OUTPUT[s['name']][:, i, :, :].reshape(
                        nout, height, width
                    ).astype(outtype),
                    proj, geo, missing_out)


def run_gipsexport(projdir, outdir, **kwargs):
    # assume a specific directory structure associated with GIPS export
    startdirs = [os.path.join(projdir, d) for d in os.listdir(projdir)]
    for startdir in startdirs:
        thisoutdir = os.path.join(outdir, os.path.split(startdir)[1])
        run(startdir, thisoutdir, **kwargs)


def main():

    parser = argparse.ArgumentParser(description='MultiTemporal Processor')

    # NOTE: do not use argparse defaults. Will be handled separately below
    # TODO: allow all arguments to be specified on the command line
    # except "conf" which maybe will go away

    # execution parameters
    parser.add_argument('--nproc', type=int,
                        help='Number of processors to use')

    parser.add_argument('--blkrow', type=int,
                        help='Rows per block')

    parser.add_argument('--compthresh', type=float,
                        help='Completeness required')

    parser.add_argument('--dperframe', type=int,
                        help='Days per time step (frame)')

    parser.add_argument('--projdir',
                        help='Directory containing timeseries')

    parser.add_argument('--nongips', action="store_true",
                        help='Projdir is not gips compliant')

    parser.add_argument('--ymd', action="store_true",
                        help='Date string is YYMMDD (not GIPS-compliant)')

    parser.add_argument('--projname',
                        help='Project name to use for output files')

    parser.add_argument('--outdir',
                        help='Directory in which to place outputs')

    # consider getting rid of this and just using stdin
    # otherwise --conf is an argument that is a file that has arguments
    # which could be circular
    parser.add_argument('--conf', help='File containing json configuration')

    args = parser.parse_args()

    # steps dictionary lives in conf
    if args.conf is not None:
        # if --conf was specified, read the file and parse the json
        with open(args.conf) as cf:

            conf = json.load(cf)
    else:
        # get json config from stdin
        conf = json.load(sys.stdin)

    # override json configuration options with those from CLI
    args_dict = dict((k,v) for k,v in vars(args).iteritems() if v is not None)
    conf.update(args_dict)

    # apply defaults
    # done after above so that defaults from one do not overwrite the other
    # ok for now -- some things just don't have defaults
    defaults = {
        'nproc' : 1,
        'nongips' : False,
        'ymd' : False,
        'blkrow' : 10,
        'compthresh' : 0.0,
        'dperframe' : 1,
        'missing_out' : -32768.,
    }
    for d in defaults:
        conf[d] = conf.get(d, defaults[d])
    run_func = run
    if not conf['nongips']:
        run_func = run_gipsexport
    try:
        run_func(**conf)
    except Exception as e:
        from pprint import pformat
        import traceback
        print(e)
        print(traceback.format_exc())
        import pdb; pdb.set_trace();

        sys.exit(333)
    return sys.exit(0)


if __name__ == "__main__":
    main()
