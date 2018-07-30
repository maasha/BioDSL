FROM debian
RUN apt-get update && apt-get install -y \
  build-essential \
  ruby \
  ruby-dev \
  && rm -rf /var/lib/apt/lists/*
RUN useradd -ms /bin/bash biodsl
RUN gem update
USER biodsl
RUN gem install --user-install BioDSL

FROM debian
RUN apt-get update && apt-get install -y \
  bzip2 \
  file \
  gcc \
  gnuplot \
  make \
  ruby \
  ruby-dev \
  && rm -rf /var/lib/apt/lists/*
RUN useradd -ms /bin/bash biodsl
USER biodsl
COPY test /tmp
WORKDIR /home/biodsl
RUN mkdir -p data/test
COPY --from=0 /home/biodsl/.gem ./.gem
COPY config/.bashrc .
