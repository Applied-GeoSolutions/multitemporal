#!/usr/bin/env bash
virtualenv --system-site-packages venv
source venv/bin/activate
pip install -e .
