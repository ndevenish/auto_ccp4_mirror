FROM rust:buster

ARG BREEZY_VERSION=3.2.2

RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install setuptools_rust configobj fastbencode patiencediff dulwich fastimport Cython

# Use pypi, because self-building seems to have errors
RUN pip3 install breezy

# WORKDIR /opt
# RUN brz checkout ${BZR_REPO_URL} imported_repo


# RUN mkdir /opt/breezy && \
#     curl -L https://github.com/breezy-team/breezy/archive/refs/tags/brz-${BREEZY_VERSION}.tar.gz \
#     | tar --strip-components=1 -xzC /opt/breezy