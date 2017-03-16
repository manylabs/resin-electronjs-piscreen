FROM resin/raspberrypi2-python:3.6

# Install system deps for node & livestreamer
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  curl \
  openssh-server \
  omxplayer \
  librtmp-dev \
  libffi-dev \
  # Remove package lists to free up space
  && rm -rf /var/lib/apt/lists/*

# install latest node
RUN curl -sL 'https://deb.nodesource.com/setup_7.x' | sudo -E bash - \
  && sudo apt-get install -y nodejs \
  && npm config set unsafe-perm true -g --unsafe-perm \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

# install python modules
# use `RUN pip install -r /requirements.txt` for better container caching
# RUN python -m pip install python-librtmp streamlink
RUN python -m pip install python-librtmp

# use beardypig/streamlink:ustream-websockets branch b/c ustream plugin not
# fixed in main streamlink repo yet (Mar 2017)
# https://github.com/beardypig/streamlink/tree/ustream-websockets
#
# multiple COPY directives help reduce docker build cache invalidation
COPY lib /app/lib/
WORKDIR /app/lib/streamlink-src
RUN python setup.py install

# global install forever
RUN npm install -g forever

# install node deps from package.json
WORKDIR /app
# COPY src src/
COPY bin bin/
COPY kijani-poller.js package.json /app/
RUN npm install

# TODO notsure
# Enable systemd
ENV INITSYSTEM on

# exec our app.
CMD npm start
# CMD ["npm", "start"]
# CMD forever kijani-poller.js
# CMD ["node", "/usr/bin/forever start -o /app/out.log -e /app/err.log --spinSleepTime 500 kijani-poller.js"]
