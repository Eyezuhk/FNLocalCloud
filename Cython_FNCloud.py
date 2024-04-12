from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize("FNCloud.pyx")
)


#python Cython_FNCloud.py build_ext --inplace
