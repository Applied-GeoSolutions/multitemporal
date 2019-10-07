FROM ubuntu:16.04

# TODO don't use system pip nor system python packages at all because
# they're all probably old and stale
RUN echo "deb http://ppa.launchpad.net/ubuntugis/ppa/ubuntu xenial main" >> \
       /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160 \
    && apt-get -y update \
    && apt-get install -y --allow-unauthenticated \
    gcc \
    python \
    python-pip \
    python-numpy \
    python-scipy \
    python-pandas \
    python-gdal \
    libgdal-dev \
    gdal-bin \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove \
    && apt-get -y autoclean

COPY . /multitemporal

# no such file:  # && pip install -r requirements.txt \
# broke due to https://github.com/pypa/pip/issues/5599:  # && pip install --upgrade pip \
# TODO install cython via setup.py (or whatever correct way)
RUN cd /multitemporal && \
    pip install cython && pip install -e . && python setup.py build_ext --inplace

WORKDIR /multitemporal
VOLUME data
