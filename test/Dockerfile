# A Docker image for running Community's tests on CircleCI
#
# To update the image, modify the file and then run `docker build .` from within this directory
#
# To push an image to Docker Hub:
#
#    docker tag <IMAGE ID> recursecenter/community-ci:<TAGNAME e.g. ruby-2.4.5>
#    docker push recursecenter/community-ci:<TAGNAME>

FROM circleci/ruby:2.4.5-node-browsers
MAINTAINER davidbalbert@gmail.com

RUN sudo apt install -y postgresql-client

RUN sudo apt-get install -y --no-install-recommends openjdk-8-jdk

RUN sudo curl -o /usr/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
RUN sudo chmod a+x /usr/bin/lein
RUN /usr/bin/lein
