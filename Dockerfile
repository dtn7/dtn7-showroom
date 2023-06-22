ARG ARCH=

# == build dtn7-rs, dtn-dwd, dtnchat

FROM ${ARCH}rust:1.64 as builder
WORKDIR /root
RUN rustup component add rustfmt
RUN git clone https://github.com/dtn7/dtn7-rs  && cd dtn7-rs && \
    git checkout 43fac1cc2ead3a8fa9e1825f8265a77dd9298daa && \
    cargo install --locked --bins --examples --root /usr/local --path examples && \
    cargo install --locked --bins --examples --root /usr/local --path core/dtn7
RUN cargo install --locked --bins --examples --root /usr/local dtn7-plus --git https://github.com/dtn7/dtn7-plus-rs  --rev 010202e56 dtn7-plus
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y libpango1.0-dev libatk1.0-dev libsoup2.4-dev libwebkit2gtk-4.0-dev cmake && \
    rm -rf /var/lib/apt/lists/*
RUN cargo install --bins --examples --root /usr/local --git https://github.com/gh0st42/coreemu-rs --rev 326a6f7
RUN git clone https://github.com/stg-tud/dtn-dwd && cd dtn-dwd && \
    git checkout b78e241 && \
    cargo install --root /usr/local --path backend/ && \
    cargo install --root /usr/local --path client/
RUN git clone https://github.com/gh0st42/dtnchat && cd dtnchat && \
    git checkout 93f1450 && \
    cargo install --bins --examples --root /usr/local --path .

RUN apt-get update && apt-get -y install libudev-dev protobuf-compiler

RUN git clone https://github.com/BigJk/dtn7-rs-lora-ecla.git && cd dtn7-rs-lora-ecla && \
    git checkout 0277dbc8151300e260698cf32beab7bcb98d58f5 && \
    cargo install --locked --bins --examples --root /usr/local --path .

# == build wtf, loraemu

FROM ${ARCH}golang:1.19 as gobuilder

ARG wtfversion=v0.41.0

RUN git clone https://github.com/wtfutil/wtf.git $GOPATH/src/github.com/wtfutil/wtf && \
    cd $GOPATH/src/github.com/wtfutil/wtf && \
    git checkout $wtfversion

ENV GOPROXY=https://proxy.golang.org,direct
ENV GO111MODULE=on
ENV GOSUMDB=off

WORKDIR $GOPATH/src/github.com/wtfutil/wtf

ENV PATH=$PATH:./bin

RUN make build && \
    cp bin/wtfutil /usr/local/bin/

# == fetch node frontend building of loraemu

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 19.7.0

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    141F07595B7B3FFE74309A937405533BE57C7D57 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    61FC681DFB92A079F1685E77973F295594EC4689 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
  ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.gz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.gz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-$ARCH.tar.gz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.gz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version

# == build loraemu + frontend and move files to /usr/local/bin

RUN git clone https://github.com/bigjk/loraemu.git $GOPATH/src/github.com/bigjk/loraemu && \
    cd $GOPATH/src/github.com/bigjk/loraemu && \
    git checkout 182c303c4b03355f1300e8bbb05c3c9caf10ce6f && \
    ./build_all.sh && \
    mv ./release/emu ./release/loraemu && \
    mv ./release/log-inspect ./release/loraemu-log-inspect && \
    mv -v ./release/* /usr/local/bin/

WORKDIR $GOPATH/src/github.com/bigjk/loraemu

FROM ${ARCH}gh0st42/coreemu-lab:1.1.0

# install stuff for vnc session

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y lxde-core lxterminal \
    tightvncserver firefox wmctrl xterm \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    pan tin slrn thunderbird \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash && \
    apt-get install -y nodejs && \
    npm i -g node-red && \
    npm i -g node-red-dashboard && \
    npm i -g node-red-node-ui-list && \
    npm i -g node-red-contrib-web-worldmap && \
    npm i -g node-red-contrib-proj4 && \
    mkdir -p /root/nodered/ && \
    cd /root/nodered/ && \
    #    wget https://raw.githubusercontent.com/dtn7/dtn7-plus-rs/master/extra/dtnmap.json && \
    rm -rf /var/lib/apt/lists/*

COPY configs/dtnmap.json /root/nodered/

# copy executables from builders

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=gobuilder /usr/local/bin/* /usr/local/bin/
COPY --from=gobuilder /usr/local/bin/frontend /usr/local/bin/frontend

RUN touch /root/.Xresources
RUN touch /root/.Xauthority
WORKDIR /root
RUN mkdir .vnc Desktop
COPY configs/Xdefaults /root/.Xdefaults
COPY scripts/fakegps.sh /usr/local/bin/fakegps.sh
COPY scripts/dtn7-* /usr/local/bin/

RUN mkdir -p /root/.core/myservices && mkdir -p /root/.coregui/custom_services && mkdir -p /root/.coregui/icons
COPY core_services/* /root/.core/myservices/
COPY coregui/config.yaml /root/.coregui/
COPY coregui/icons/* /root/.coregui/icons/
COPY scenarios/*.xml /root/.coregui/xmls/
COPY configs/dtn7.yml /root/
COPY loraemu/ /root/loraemu

# --------------------------- moNNT.py Installation ---------------------------

COPY configs/dtnnntp /root/

RUN pip install poetry==1.1.13 && \
    mkdir -p /app/moNNT.py && \
    git clone https://github.com/teschmitt/moNNT.py.git /app/moNNT.py && \
    cd /app/moNNT.py && git checkout 4ed3d9b && \
    mv /root/monntpy-config.py /app/moNNT.py/backend/dtn7sqlite/config.py && \
    mv /root/db.sqlite3 /app/moNNT.py
WORKDIR /app/moNNT.py

RUN poetry install --no-interaction --no-ansi --no-root --no-dev

COPY scripts/dtnnntp-refresher.py /app
ENV DB_PATH="/app/moNNT.py/db.sqlite3" \
    NNTPPORT=1190 \
    NNTPSERVER=10.0.0.21


# --------------------------- dtn7zero Installation ---------------------------
RUN sudo pip3 install --upgrade requests && pip3 install dtn7zero==0.0.6 && sudo apt install python3-matplotlib

# pre-load and parse demo temperature data, will be stored in /app/data/temps.json
RUN mkdir -p /root/.coregui/scripts
COPY scripts/prepare_weather_data.py /root/.coregui/scripts
RUN python3 /root/.coregui/scripts/prepare_weather_data.py


# -----------------------------------------------------------------------------

# add new user for tunneling into gateway node in DTN-NNTP scenario
# RUN useradd --create-home --no-log-init --shell /bin/bash joe
# USER joe
# RUN ssh-keygen -t rsa -f "$HOME/.ssh/id_rsa" -N ""
# USER root

# COPY xstartup with start for lxde
COPY configs/xstartup /root/.vnc/
COPY scripts/coreemu.sh /root/Desktop
COPY scripts/entrypoint.sh /entrypoint.sh

RUN echo "export USER=root" >> /root/.bashrc
ENV USER root
RUN printf "sneakers\nsneakers\nn\n" | vncpasswd

EXPOSE 22
EXPOSE 1190
EXPOSE 5901
EXPOSE 50051
EXPOSE 8291
ENTRYPOINT [ "/entrypoint.sh" ]
WORKDIR /root
