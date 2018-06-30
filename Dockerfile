FROM nginx:1.13
LABEL maintainer="Jason Wilder mail@jasonwilder.com"

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    build-essential git golang-go unzip \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*


# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

RUN git clone https://github.com/jwilder/docker-gen.git \
 && export GOPATH=$HOME/go               \
 && export PATH=$PATH:$GOPATH/bin        \
 && go env                               \
 && cd docker-gen                        \
 && git branch -a                        \
 && git log -n 3                         \
 && make get-deps                        \
 && go get github.com/jwilder/docker-gen \
 && make docker-gen                      \
 && cp ./docker-gen /usr/local/bin/.     \
 && cd ..                                \
 && rm -rf docker-gen                    \
 && docker-gen -version

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
