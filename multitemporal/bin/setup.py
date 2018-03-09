from distutils.core import setup, Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy
import os

setup(
  name = 'multitemporal',
  cmdclass = {'build_ext': build_ext},
  ext_modules = cythonize("*.pyx"),
  include_dirs=[numpy.get_include()]  
)
