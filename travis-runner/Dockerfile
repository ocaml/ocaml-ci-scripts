FROM docker:1.7

RUN apk update && apk add bash wget git

RUN adduser -S travis
RUN echo 'travis ALL=(ALL) ALL' >> /etc/sudoers
RUN mkdir -p /root/build/orig && chmod a+w /root/build/orig

ADD travis-runner.sh /build-script/travis-runner.sh

CMD ["/build-script/travis-runner.sh"]
