FROM       debian:stable
MAINTAINER jaejeon_lim <jaejeon_lim@tmax.co.kr>

RUN apt-get update && apt-get install -y \
	libdbi-perl libyaml-libyaml-perl libhash-merge-perl \
	libstring-format-perl libtimedate-perl libyaml-tiny-perl \
	libdpkg-perl libdbd-pg-perl dctrl-tools moreutils dose-builddebcheck \
	dose-distcheck libany-uri-escape-perl \
	postgresql-13-debversion \
	procmail \
	cron wget tinysshd ipsvd \
	procps

RUN adduser --disabled-password --gecos "" wbadm

RUN adduser --disabled-password buildd-all --gecos ""
COPY ssh_all /home/buildd-all/.ssh

RUN adduser --disabled-password buildd-amd64 --gecos ""
COPY ssh_amd64 /home/buildd-amd64/.ssh

RUN adduser --disabled-password buildd-i386 --gecos ""
COPY ssh_i386 /home/buildd-i386/.ssh

RUN adduser --disabled-password buildd-arm64 --gecos ""
COPY ssh_arm64 /home/buildd-arm64/.ssh

RUN echo DUMMY

COPY wanna-build /srv/wanna-build
RUN ln -s /srv/wanna-build/bin/wanna-build /usr/local/bin/wanna-build

COPY trigger.local /srv/wanna-build/triggers/
RUN chmod a+x /srv/wanna-build/triggers/trigger.local

RUN touch /srv/wanna-build/etc/graph-data

RUN chown wbadm. -R /srv/wanna-build

COPY crontab /etc/crontab

COPY work /etc/work

COPY init /etc/init
RUN chmod +x /etc/init

CMD ["/etc/init"]
