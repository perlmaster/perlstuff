package Deploy;

use strict;
use warnings;
use Carp;
use Sys::Hostname;

use constant TO       => '<barry.kimelman@eds.com>';
use constant SENDMAIL => '/usr/lib/sendmail';

our(@Fibonacci);
our($s_Subject);
our(@a_Body);
our($s_Status);

# Subs: Used in Error Handling
    {
    ################################################################################################
    #
    sub EMail {
        my(@a)=@_;
        TRY: for my $try (1..3) {
            eval {
                ### Trying to sendmail
                open (MAIL, "| ".SENDMAIL." -t -oi -oem") or die "opening ".SENDMAIL.": $!";
                print MAIL join("\n",@a);
                close MAIL or die "sendmail wasn't happy!";
                no warnings "all"; last TRY; use warnings "all";
            };
            ### Failed: $try
            if ($try < 3) {
                sleep(rand(Fibonacci__($try+1)));
            } else {
                confess "Can't sendmail!";
            };
        }; # TRY
        return;
    }; # EMail: Done

    ################################################################################################
    # return the n-th Fibonacci number
    sub Fibonacci__ { # (n)
        my($n)=@_;
        confess "Can't compute Fibonacci($n)!" if ($n < 0);
        if (!defined($Fibonacci[$n])) {
            for my $i (@Fibonacci..$n) {
                $Fibonacci[$i]=$Fibonacci[$i-1]+$Fibonacci[$i-2];
            };
        };
        return $Fibonacci[$n];
    }; # Fibonacci: Done
}; # Subs: Used in Error Handling

BEGIN { # Runs as soon as the block itself is compiled
    # Need this to use Fibonacci
    (@Fibonacci)=(1,1);
    my @a_EMailHeader = ('To: '.TO,"From: <$0\@".Sys::Hostname::hostname());
    # The 'began compilation' message:
    EMail(@a_EMailHeader,"Subject: '$0' began compilation.",'',@a_Body);
    # Catch the compilation errors
    $SIG{__DIE__}=sub {
        $SIG{__DIE__}='DEFAULT';
        EMail(@a_EMailHeader,"Subject: '$0' failed compilation!",'',@_);
        die "@_";
    };
}; # BEGIN

INIT { # Runs as soon as the compilation is complete
    # Hope for the best! ---
    $s_Subject="Subject: '$0 @ARGV' ";
    $s_Status='was successful.';
    # Set up message collection for $SIG{__DIE__} and $SIG{__WARN__}
    # --- but prepare for the worst!
    # Under SunOS
    $SIG{__DIE__}=sub {
         push(@a_Body,@_);
         $s_Status='died during execution!';
    };
    $SIG{__WARN__}=sub {
         push(@a_Body,@_);
         $s_Status='produced warning(s) during execution!'
    };
}; # INIT

END { # Runs only if compilation was successful - hence it reports run time errors
    my @a_EMailHeader = ('To: '.TO,"From: <$0\@".Sys::Hostname::hostname());
    EMail(@a_EMailHeader,"$s_Subject $s_Status",'',@a_Body) if ($s_Status);
}; # END

    1;
__END__
