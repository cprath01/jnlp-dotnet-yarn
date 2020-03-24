FROM jenkins/jnlp-slave

USER root

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/* sudo

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.1.804

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='82b039856dadd2b47fa56a262d1a1a389132f0db037d4ee5c0872f2949c2cd447c33a978e1f532783119aa416860e03f26b840863ca3a97392a4b77f8df5bf66' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# set up node
ENV NODE_VERSION 10.19.0
ENV YARN_VERSION 1.17.3
ENV NODE_DOWNLOAD_SHA 36d90bc58f0418f31dceda5b18eb260019fcc91e59b0820ffa66700772a8804b
ENV NODE_DOWNLOAD_URL https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz

RUN curl -SL "$NODE_DOWNLOAD_URL" --output nodejs.tar.gz \
    && echo "$NODE_DOWNLOAD_SHA nodejs.tar.gz" | sha256sum -c - \
    && tar -xzf "nodejs.tar.gz" -C /usr/local --strip-components=1 \
    && rm nodejs.tar.gz \
    && npm i -g yarn@$YARN_VERSION \
    && yarn global add webpack@4 webpack-cli@2 \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

USER jenkins

RUN dotnet tool install --global dotnet-sonarscanner
RUN echo '#!/bin/bash\n\
cat << \EOF >> ~/.bash_profile\n\
export PATH="$PATH:/home/jenkins/.dotnet/tools"\n\
EOF\n'\
> ~/updatePath.sh
RUN chmod a+x updatePath.sh
RUN ./updatePath.sh
RUN rm ./updatePath.sh