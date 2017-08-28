FROM #{FROM}

ENV DL_PREFIX=http://cdn.azul.com/zulu/bin
ENV ZULUJDK_VERSION=#{ZULU_VERSION}

# Pull tgz version of ZuluJDK
RUN curl -O ${DL_PREFIX}/${ZULUJDK_VERSION}.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    tar xf ${ZULUJDK_VERSION}.tar.gz && \
    mv ${ZULUJDK_VERSION}/jre /usr/lib/jvm/ && \
    rm -rf ${ZULUJDK_VERSION} ${ZULUJDK_VERSION}.tar.gz

ENV JAVA_HOME="/usr/lib/jvm/${ZULUJDK_VERSION}"

# Enforce java version through path. This is needed to override JDK version installed later as dependencies.
# Setting up alternatives (update-alternatives) correctly might be a better way in debian.
ENV PATH="${JAVA_HOME}/bin/:${PATH}"