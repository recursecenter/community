# A Docker image for running Community's tests on CircleCI
#
# To update the image, modify the file and then run `docker build .` from within this directory
#
# To push an image to Docker Hub:
#
#    docker tag <IMAGE ID> recursecenter/community-ci:<TAGNAME e.g. ruby-2.6.3>
#    docker push recursecenter/community-ci:<TAGNAME>

FROM circleci/ruby:2.6.6-node-browsers
MAINTAINER davidbalbert@gmail.com

RUN sudo apt install -y postgresql-client software-properties-common

RUN sudo apt remove openjdk-11-*

# Debian 10 doesn’t have OpenJDK 8.
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
RUN sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
RUN sudo apt update
RUN sudo apt install -y --no-install-recommends adoptopenjdk-8-hotspot

RUN sudo curl -o /usr/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
RUN sudo chmod a+x /usr/bin/lein
RUN /usr/bin/lein
