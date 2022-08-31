package WB::QD;

use strict;
use IO::Uncompress::AnyInflate qw(anyinflate);
use Dpkg::Version (); # import nothing
if ( defined $Dpkg::Version::VERSION ) {
    *vercmp = \&Dpkg::Version::version_compare;
} else {
    *vercmp = \&Dpkg::Version::vercmp;
}
use Dpkg::Arch qw(debarch_is);
use Data::Dumper;

sub readsourcebins {
    my $arch = shift;
    my $pasfile = shift;
    my $SRC = shift;
    my $BIN = shift;
    my $binary = {};

    my $pas = {};
    local($/) = "\n";
    open(my $pasf, '<', $pasfile);
    while(<$pasf>) {
        chomp;
        s,\s*#.*,,;
        next unless $_;
        my ($p, $c) = split(/:\s*/);
        $pas->{$p} = { arch => [ split(/\s+/, $c) ], mode => substr($c, 0, 1) ne '!' };
    }
    close $pasf;

    my $srcs = {};
    local($/) = ""; # read in paragraph mode

    foreach my $s (@$SRC) {
        my $S = new IO::Uncompress::AnyInflate($s) || return "WB::QD::SRC can't open $s";
        while(<$S>) {
            my $p={};
            /^Package:\s*(\S+)$/mi and $p->{'name'} = $1;
            /^Version:\s*(\S+)$/mi and $p->{'version'} = $1;
            /^Binary:\s*(.*)$/mi and $p->{'binary'} = $1;
            /^Architecture:\s*(.+)$/mi and $p->{'arch'} = $1;
            /^Priority:\s*(\S+)$/mi and $p->{'priority'} = $1;
            /^Section:\s*(\S+)$/mi and $p->{'section'} = $1;
            /^Build-Depends:\s*(.*)$/mi and $p->{'depends'} = $1;
            /^Build-Depends-Arch:\s*(.*)$/mi and $p->{'depends-arch'} = $1;
            /^Build-Depends-Indep:\s*(.*)$/mi and $p->{'depends-indep'} = $1;
            /^Build-Conflicts:\s*(.*)$/mi and $p->{'conflicts'} = $1;
            /^Build-Conflicts-Arch:\s*(.*)$/mi and $p->{'conflicts-arch'} = $1;
            /^Build-Conflicts-Indep:\s*(.*)$/mi and $p->{'conflicts-indep'} = $1;

            next unless $p->{'name'} and $p->{'version'};
            foreach my $tarch (split(/\s+/, $p->{'arch'})) {
                if ($arch eq 'all') {
                    $p->{'for-us'} = 1 if $tarch eq 'all';
                } else {
                    $p->{'for-us'} = 1 if debarch_is($arch, $tarch);
                }
            }

            # ignore if package already exists with higher version
            if ($srcs->{$p->{'name'}}) {
                next if (vercmp($srcs->{$p->{'name'}}->{'version'}, $p->{'version'}) > 0);
            }
            if ($p->{'binary'}) {
                $p->{'binary'} = [ split(/,? /, $p->{'binary'}) ];
            }
            $srcs->{$p->{'name'}} = $p;
        }
        close $S;
    }

    foreach my $p (@$BIN) {
        my $P = new IO::Uncompress::AnyInflate($p) || return "WB::QD::PKGS can't open $p";
        while(<$P>) {
            my $p;
            /^Version:\s*(\S+)$/mi and $p->{'version'} = $1;
            /^Version:\s*(\S+)\+b([0-9]+)$/mi and $p->{'version'} = $1 and $p->{'binnmu'} = $2;
            /^Architecture:\s*(\S+)$/mi and $p->{'arch'} = $1;
            /^Package:\s*(\S+)$/mi and $p->{'binary'} = $1;
            /^Package:\s*(\S+)$/mi and $p->{'source'} = $1;
            /^Source:\s*(\S+)$/mi and $p->{'source'} = $1;
            /^Source:\s*(\S+)\s+\((\S+)\)$/mi and $p->{'source'} = $1 and $p->{'version'} = $2;

	    if ($arch ne 'all') {
                # consider packages as non-existant if it's all but outdated
	        # arch:all and ver(binary) < ver(source) => skip
	        next if $p->{'arch'} eq 'all' && $srcs->{$p->{'source'}} && $srcs->{$p->{'source'}}->{'version'} && vercmp($srcs->{$p->{'source'}}->{'version'}, $p->{'version'}) > 0;
		# not for the current architecture or arch:all => skip
                next unless $p->{'arch'} eq 'all' || $p->{'arch'} eq ${arch};
	    }
            # register the binary if there isn't a newer one in the hash yet
            $binary->{$p->{'binary'}} = { 'version' => $p->{'version'}, 'arch' => $p->{'arch'}}
                unless $binary->{$p->{'binary'}} and vercmp($binary->{$p->{'binary'}}->{'version'}, $p->{'version'}) < 0;

            #next if $pas->{$p->{'binary'}} && pasignore($pas->{$p->{'binary'}}, $arch);

            # only continue if it's arch-specific...
            next if ($arch ne 'all') && ($p->{'arch'} eq 'all');
            next if ($arch eq 'all') && ($p->{'arch'} !~ /all/);

            # annotate the source package if present, continue otherwise
            next unless $srcs->{$p->{'source'}};

            $srcs->{$p->{'source'}}->{'compiled'} = 1;

            # TODO: ???
            next unless $srcs->{$p->{'source'}}->{'version'} eq $p->{'version'};
            $srcs->{$p->{'source'}}->{'installed'} = 1;

            next unless $p->{'binnmu'};
            next if ($srcs->{$p->{'source'}}->{'binnmu'}) && ($srcs->{$p->{'source'}}->{'binnmu'} > $p->{'binnmu'});
            $srcs->{$p->{'source'}}->{'binnmu'} = $p->{'binnmu'};
        }
        close $P;
    }

    SRCS:
    for my $k (keys %$srcs) {
        if ($srcs->{$k}->{'installed'}) {
            $srcs->{$k}->{'status'} = 'installed';
            delete $srcs->{$k}->{'installed'};
        } elsif ($srcs->{$k}->{'compiled'}) {
            $srcs->{$k}->{'status'} = 'out-of-date';
        } else {
            $srcs->{$k}->{'status'} = 'uncompiled';
        }
        delete $srcs->{$k}->{'compiled'};
        $srcs->{$k}->{'status'} = 'installed' if $srcs->{$k}->{'arch'} && $srcs->{$k}->{'arch'} eq 'all' and $arch ne 'all';
        
        if (!$srcs->{$k}->{'for-us'} && $srcs->{$k}->{'status'} ne 'installed') {
            $srcs->{$k}->{'status'} = 'arch-not-in-arch-list';
        }
        delete $srcs->{$k}->{'for-us'};

        if ($srcs->{$k}->{'arch'} eq 'all' and $arch ne 'all') {
            $srcs->{$k}->{'status'} = 'arch-all-only';
            delete $srcs->{$k}->{'arch'};
            next;
        }
        delete $srcs->{$k}->{'arch'};
        
        if (pasignore($pas->{'%'.$k}, $arch)) {
            $srcs->{$k}->{'status'} = 'packages-arch-specific';
            next;
        }
        for my $bin (@{$srcs->{$k}->{'binary'}}) {
            $srcs->{$k}->{'pas'} = 1 if pasignore($pas->{$bin}, $arch);
            next if pasignore($pas->{$bin}, $arch);
            next if $binary->{$bin} and $binary->{$bin}->{'arch'} eq 'all' and $arch ne 'all';
            next SRCS;
        }
        if ($srcs->{$k}->{'pas'}) {
            $srcs->{$k}->{'status'} = 'packages-arch-specific';
        } else {
            $srcs->{$k}->{'status'} = 'overwritten-by-arch-all';
        }
        delete $srcs->{$k}->{'pas'};
    }
    $srcs->{'_binary'} = $binary;
    local($/) = "\n";

    return \$srcs;
}

sub pasignore {
    my $p = shift;
    my $arch = shift;
    if ($p && $p->{'mode'}) {
        return 1 unless grep { $_ eq $arch } @{$p->{'arch'}};
    }
    if ($p && not $p->{'mode'}) {
        return 1 if grep /^!$arch$/, @{$p->{'arch'}};
    }
    return 0;
}

1;
