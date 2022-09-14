ARG ARCH=

FROM ${ARCH}rust:1.62.1 as builder
WORKDIR /root
RUN rustup component add rustfmt
RUN git clone https://github.com/dtn7/dtn7-rs  && cd dtn7-rs && \
    git checkout 0bb1fa3 && \
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


FROM ${ARCH}gh0st42/coreemu-lab:1.0.0

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
COPY --from=builder /usr/local/bin/* /usr/local/bin/

COPY --from=gobuilder /usr/local/bin/* /usr/local/bin/

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


# --------------------------- moNNT.py Installation ---------------------------

RUN pip install poetry==1.1.13 && \
    mkdir -p /app/moNNT.py && \
    mkdir -p /root/.pan2 && \
    git clone https://github.com/teschmitt/moNNT.py.git /app/moNNT.py
WORKDIR /app/moNNT.py
RUN poetry install --no-interaction --no-ansi --no-root --no-dev

COPY configs/monntpy-config.py /app/moNNT.py/backend/dtn7sqlite/config.py
COPY configs/.pan2 /root/.pan2
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
ENTRYPOINT [ "/entrypoint.sh" ]
WORKDIR /root
