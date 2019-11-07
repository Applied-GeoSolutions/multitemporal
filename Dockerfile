FROM geographica/gdal2:latest

# TODO don't use system pip nor system python packages at all because
# they're all probably old and stale
RUN apt-get -y update && apt-get install -y --allow-unauthenticated python3-pip

COPY . /multitemporal

# no such file:  # && pip install -r requirements.txt \
# broke due to https://github.com/pypa/pip/issues/5599:  # && pip install --upgrade pip \
# TODO install cython et al via setup.py (or whatever correct way)
RUN cd /multitemporal && pip3 install Cython numpy sharedmem pytest pytest-cov future && \
    pip3 install -e . && python3 setup.py build_ext --inplace
RUN apt-get -y autoremove && apt-get -y autoclean

WORKDIR /multitemporal
VOLUME data
