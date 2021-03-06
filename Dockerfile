FROM jenkins/jenkins:lts

MAINTAINER Steve Ochoa (github: boostninja)

# Do not display some warning messages
ENV DEBIAN_FRONTEND noninteractive

# Set Env variables
ENV maven_version 3.5.2
ENV MAVEN_HOME /opt/maven
ENV python_version 3.8.5

USER root
RUN apt-get update \
          && apt-get install -y wget curl openssh-server nano sudo
          
# Set alias for Nano 
RUN echo "alias nano='export TERM=xterm && nano'" >> /root/.bashrc
# Add jenkins user to sudoers
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# Install Nodejs and npm
RUN apt-get install -y build-essential
RUN curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
RUN apt-get install -y nodejs

# Install Serverless and plugins
RUN npm install -g serverless@1.80.0
RUN npm install serverless-pseudo-parameters@1.6.0
RUN npm install serverless-plugin-log-retention@1.0.3
RUN npm install --save serverless-cloudformation-changesets
RUN npm install --save serverless-plugin-additional-stacks

# Install aws-cli
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# Install Docker Client to access host 
ARG DOCKER_CLIENT=docker-17.12.0-ce.tgz
RUN cd /tmp/ \
	&& curl -sSL -O https://download.docker.com/linux/static/stable/x86_64/${DOCKER_CLIENT} \
	&& tar zxf ${DOCKER_CLIENT} \
	&& mkdir -p /usr/local/bin \
	&& mv ./docker/docker /usr/local/bin \
	&& chmod +x /usr/local/bin/docker \
	&& rm -rf /tmp/*

# Download maven
ARG maven_filename="apache-maven-${maven_version}-bin.tar.gz"
ARG maven_filemd5="948110de4aab290033c23bf4894f7d9a"
ARG maven_url="http://archive.apache.org/dist/maven/maven-3/${maven_version}/binaries/${maven_filename}"
ARG maven_tmp="/tmp/${maven_filename}"

RUN wget --no-verbose -O ${maven_tmp}  ${maven_url}
RUN echo "${maven_filemd5} ${maven_tmp}" | md5sum -c

# Install maven
RUN tar xzf ${maven_tmp}  -C /opt/ \
        && ln -s /opt/apache-maven-${maven_version} ${MAVEN_HOME} \
        && ln -s ${MAVEN_HOME}/bin/mvn /usr/local/bin

ENV PATH ${MAVEN_HOME}/bin:$PATH

# Download & Install Python
ARG python_filename="Python-${python_version}.tar.xz"
ARG python_url="https://www.python.org/ftp/python/${python_version}/${python_filename}"
ARG python_tmp="/tmp/Python-${python_version}"
ARG pip_version="3.8"

RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
WORKDIR /tmp
RUN wget --no-verbose -O ${python_filename} ${python_url}
RUN tar -xf ${python_filename}
WORKDIR "Python-${python_version}"
RUN ./configure --enable-optimizations
RUN make
RUN make altinstall
WORKDIR /
RUN rm -rf ${python_tmp}
RUN ln -s /usr/local/bin/pip${pip_version} /usr/local/bin/pip

# Clean 
RUN  apt-get clean \
          && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_*

USER jenkins
# Set jenkins alias for nano 
RUN echo "alias nano='export TERM=xterm && nano'" >> ${JENKINS_HOME}/.bash_aliases

RUN mvn --version
