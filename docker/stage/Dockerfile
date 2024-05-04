FROM alpine:3.17

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG ZULU_DIR=zulu19.30.11-ca-jdk19.0.1-linux_musl_x64

RUN ZULU_PACK=${ZULU_DIR}.tar.gz && \
    INSTALL_DIR=/usr/lib/jvm && \
    BIN_DIR=/usr/bin && \
    MAN_DIR=/usr/share/man/man1 && \
    apk --no-cache add binutils ca-certificates wget zstd tar xz && \
    apk update && \
    apk upgrade && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk && \
    apk add --force-overwrite glibc-2.35-r0.apk && rm glibc-2.35-r0.apk && \
    wget -O gcc-libs.tar.zst https://www.archlinux.org/packages/core/x86_64/gcc-libs/download/ && \
    wget -O zlib.tar.xz https://www.archlinux.org/packages/core/x86_64/zlib/download/ && \
    tar -I zstd -xf gcc-libs.tar.zst -C /tmp && \
    tar --use-compress-program=unzstd -xf zlib.tar.xz -C /tmp && \
    mv /tmp/usr/lib/libgcc_s.so* /tmp/usr/lib/libstdc++.so* /tmp/usr/lib/libz.so* /usr/glibc-compat/lib/ && \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so.* && \
    rm -rf gcc-libs.tar.xz zlib.tar.xz /tmp/usr && \
    wget -q https://cdn.azul.com/zulu/bin/zulu19.30.11-ca-jdk19.0.1-linux_musl_x64.tar.gz && rm /root/.wget-hsts && \
    mkdir -p ${INSTALL_DIR} && \
    tar -xf ./${ZULU_PACK} -C ${INSTALL_DIR} && rm -f ${ZULU_PACK} && \
    cd ${BIN_DIR} && \
    find ${INSTALL_DIR}/${ZULU_DIR}/bin -type f -perm -a=x -exec ln -s {} . \; && \
    mkdir -p ${MAN_DIR} && \
    cd ${MAN_DIR} && \
    find ${INSTALL_DIR}/${ZULU_DIR}/man/man1 -type f -name "*.1" -exec ln -s {} . \;

ENV JAVA_HOME=/usr/lib/jvm/${ZULU_DIR}

ADD app /app/
WORKDIR app
RUN javac -cp .:binaries/* Reason.java && \
    mkdir sse && \
    javac -cp .:binaries/* Push.java && \
    mv Push.class sse
EXPOSE 4567
ENTRYPOINT ["java", "--add-opens", "java.base/java.lang=ALL-UNNAMED", "-cp", ".:binaries/*", "Reason"]
