FROM debian:latest

WORKDIR /app

ADD gpg /app/gpg

RUN cp gpg/tmax-archive*.gpg /etc/apt/trusted.gpg.d/

RUN echo "nameserver 192.168.2.135" > /etc/resolv.conf

RUN echo "deb http://ftpmaster.tmaxos.net/tmax tmax-unstable main contrib non-free" >> /etc/apt/sources.list.d/tmax-unstable.list
RUN echo "deb-src http://ftpmaster.tmaxos.net/tmax tmax-unstable main contrib non-free" >> /etc/apt/sources.list.d/tmax-unstable.list

RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get install -y sbuild buildd dupload sudo qemu-user-static binfmt-support

RUN adduser buildd sbuild

RUN touch /var/log/buildd.log; chown buildd. /var/log/buildd.log

COPY buildd-all.conf /etc/buildd/buildd.conf

COPY ssh /var/lib/buildd/.ssh
RUN chown buildd. -R /var/lib/buildd/.ssh

COPY Daemon.pm /usr/share/perl5/Buildd/Daemon.pm

COPY buildd-all.gpg /var/lib/buildd/buildd.gpg
RUN chown buildd. /var/lib/buildd/buildd.gpg

COPY init-all /etc/init

WORKDIR /var/lib/buildd

CMD ["/etc/init"]
