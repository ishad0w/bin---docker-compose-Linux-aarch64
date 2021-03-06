# Dockerfile to build docker-compose for aarch64
FROM arm64v8/python:3.8.5-buster

# Add env
ENV LANG C.UTF-8

# Set the versions
ENV DOCKER_COMPOSE_VER 1.27.3
# docker-compose requires pyinstaller (check github.com/docker/compose/requirements-build.txt)
# If this changes, you may need to modify the version of "six" below
ENV PYINSTALLER_VER 3.6
# "six" is needed for PyInstaller
ENV SIX_VER 1.15.0

# Install dependencies
# RUN apt-get update && apt-get install -y
RUN pip install --upgrade pip setuptools wheel
RUN pip install six==$SIX_VER

# Compile the pyinstaller "bootloader"
# https://pyinstaller.readthedocs.io/en/stable/bootloader-building.html
WORKDIR /build/pyinstallerbootloader
RUN curl -fsSL https://github.com/pyinstaller/pyinstaller/releases/download/v$PYINSTALLER_VER/PyInstaller-$PYINSTALLER_VER.tar.gz | tar xvz >/dev/null \
	&& cd PyInstaller*/bootloader \
	&& python3 ./waf all

# Clone docker-compose
WORKDIR /build/dockercompose
RUN git clone https://github.com/docker/compose.git . \
	&& git checkout $DOCKER_COMPOSE_VER

# Run the build steps (taken from github.com/docker/compose/script/build/linux-entrypoint)
RUN mkdir ./dist \
	&& echo $(./script/build/write-git-sha) > compose/GITSHA \
	&& pip -v install -q -r requirements.txt -r requirements-build.txt \
	&& pyinstaller docker-compose.spec \
	&& mv dist/docker-compose ./docker-compose-$(uname -s)-$(uname -m)

# Copy out the generated binary
VOLUME /dist
CMD cp docker-compose-* /dist

