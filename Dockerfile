FROM debian:unstable-slim
LABEL maintainer="erik@skogh.org"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update; apt-get -y upgrade  \
&& apt-get -qq install -y openjdk-8-jdk zip git curl pciutils wget; apt-get clean
RUN echo JAVA_HOME=`echo $(dirname $(dirname $(readlink -f $(which javac)))" >> /etc/bashrc
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install nodejs -y

RUN mkdir /jellyfin /tizen
WORKDIR /jellyfin
RUN git clone https://github.com/jellyfin/jellyfin-web.git /jellyfin/jellyfin-web \
&& git clone https://github.com/jellyfin/jellyfin-tizen.git /jellyfin/jellyfin-tizen
WORKDIR /jellyfin/jellyfin-web
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
RUN chmod a+x /root/.nvm/nvm.sh \
&& /root/.nvm/nvm.sh install 14.4.0
RUN npm install --save-dev webpack date-fns -g webpack -g webpack-cli -g yarn \
&& npx browserslist@latest --update-db \
&& npm ci --no-audit --loglevel verbose
WORKDIR /jellyfin/jellyfin-tizen
ENV JELLYFIN_WEB_DIR=/jellyfin/jellyfin-web/dist
RUN yarn install

WORKDIR /tizen
RUN wget https://download.tizen.org/sdk/Installer/tizen-studio_4.5.1/web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin \
&& chmod a+x /tizen/web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin
RUN useradd -rm -d /home/jellyfin -s /bin/bash -u 1001 jellyfin
RUN chown -R jellyfin:jellyfin /jellyfin/jellyfin-tizen
USER jellyfin
RUN bash /tizen/web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin --accept-license /home/jellyfin/tizen-studio
WORKDIR /home/jellyfin
RUN echo "export PATH=$PATH:/home/jellyfin/tizen-studio/tools/ide/bin" >> /home/jellyfin/.bashrc

USER root
RUN rm -fr /home/jellyfin/.package-manager/run/tizensdk_*/ /jellyfin/jellyfin-web/.git /jellyfin/jellyfin-tizen/.git /jellyfin/jellyfin-web.tar.gz /tizen/web-cli_Tizen_Studio_*.bin
COPY ./tizenjellyfin.sh /usr/local/bin/tizen-jellyfin
RUN chmod a+x /usr/local/bin/tizen-jellyfin \
&& chown jellyfin:jellyfin /usr/local/bin/tizen-jellyfin

USER jellyfin

ENTRYPOINT [ "/bin/bash", "-c", "exec /usr/local/bin/tizen-jellyfin \"${@}\"", "--" ]
