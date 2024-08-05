FROM public.ecr.aws/lambda/python:3.9

RUN yum install wget tar xz xz-utils gzip -y &&\
    cd /opt &&\
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz &&\
    tar -xf ffmpeg-release-amd64-static.tar.xz &&\
    rm ffmpeg-release-amd64-static.tar.xz &&\
    ln -s /opt/ffmpeg-6.1-amd64-static/ff* /usr/bin

RUN chmod +x /opt/ffmpeg-6.1-amd64-static/ff*

# Install media info

RUN yum install git automake autoconf libtool pkgconfig make gcc-c++ zlib-devel libcurl-devel -y &&\
    cd /tmp &&\
    wget https://mediaarea.net/download/binary/mediainfo/23.11/MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    tar -xf MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    rm MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    cd MediaInfo_CLI_GNU_FromSource &&\
    ./CLI_Compile.sh --with-libcurl &&\
    cd MediaInfo/Project/GNU/CLI &&\
    make install &&\
    rm -rf MediaInfo_CLI_GNU_FromSource &&\
    yum remove git automake autoconf libtool pkgconfig make gcc-c++ zlib-devel libcurl-devel -y

# Install the function's dependencies using file requirements.txt
# from your project folder.

COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

COPY src/*.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "main.handler" ]