# A Docker image for running Community's tests on CircleCI

FROM circleci/ruby:2.4.4-node
MAINTAINER davidbalbert@gmail.com

RUN sudo apt install -y postgresql-client

RUN sudo apt-get install -y --no-install-recommends openjdk-8-jdk

RUN sudo curl -o /usr/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
RUN sudo chmod a+x /usr/bin/lein
RUN /usr/bin/lein
