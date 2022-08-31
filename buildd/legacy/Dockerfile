from scratch

COPY chroot /

RUN apt-get update && apt-get install -y sbuild buildd sudo

RUN adduser buildd sbuild

RUN touch /var/log/buildd.log; chown buildd. /var/log/buildd.log

COPY buildd.conf /etc/buildd/buildd.conf

COPY ssh /var/lib/buildd/.ssh
RUN chown buildd. -R /var/lib/buildd/.ssh

RUN echo buildd.ci.tmaxos.net 192.168.0.3 >>/etc/hosts

COPY Daemon.pm /usr/share/perl5/Buildd/Daemon.pm

COPY buildd-amd64.gpg /var/lib/buildd/buildd.gpg
RUN chown buildd. /var/lib/buildd/buildd.gpg

COPY init /etc/init
CMD ["/etc/init"]
