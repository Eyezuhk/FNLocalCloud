from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize("FNCloud.pyx")
)

#python3 Cython_FNCloud.py build_ext --inplace
