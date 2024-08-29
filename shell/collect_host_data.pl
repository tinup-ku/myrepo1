#!/usr/bin/perl

use Getopt::Std;
use POSIX qw/mktime strftime/;

sub Usage () {

  my $docstring = <<'END_DOC';
           __  __   _    _       _
     /\   |  \/  | | |  | |     (_)
    /  \  | \  / | | |  | |_ __  _  _  _
   / /\ \ | |\/| | | |  | | '_ \| |\ \/ /
  / ____ \| |  | | | |__| | | | | | >  <
 /_/    \_\_|  |_|  \____/|_| |_|_|/_/\_\

 This script collects the following data

    SCANSUM         Sum of this script

    NASMNT          Mounted NFS Directories

    GROUP           Contents of /etc/group
    PASSWD          Contents of /etc/passwd
    SSSD            Contents of /etc/sssd/sssd.conf
    VAS             Contents of /etc/opt/quest/vas/vas.conf
    LASTJOIN        Contents of /etc/opt/quest/vas/lastjoin
    PMUL            Contents of /etc/opt/quest/qpm4u/pm.settings
    USERSALLOW      Contents of /etc/opt/quest/vas/users.allow
    OSVERSION       Contents of /etc/redhat-release

    GROUPCHECK      Results of grpck
    PASSWDCHECK     Results of pwdck

    QPMRPM          List of installed qpm rpms
    INSTALLDATE     Server installation date (from filesystem rpm)

    LOCALBIN        File listing of /usr/local/bin
    PROFILES        File listing of /etc/profile.d
    RSYSLOG         File listing of /etc/rsyslog.d

    PMRUN_CT        Previous days "pmrun.*session opened for user" count
    SUDO_CT         Previous days "sudo.*session opened for user" count

    SUDOSUM         sum of /etc/sudoers and /etc/sudoers.d/*
    SUDO            Contents of /etc/sudoers and /etc/sudoers.d/*

END_DOC

  print "$docstring\n";
  exit;

}

getopts("hd:", \%opt);

if (defined $opt{h}) {
  Usage;
}


if ( -x "/bin/timeout" ) {
  $timeout = "/bin/timeout -s9 10";
} elsif ( -x "/usr/bin/timeout" ) {
  $timeout = "/usr/bin/timeout -s9 10";
} else {
  $timeout = "";
}


###### SubRoutines ######

sub calculate_sum {
  my ($key, $ck_file) = @_;

  $file_string = "";

  open(F, "< $ck_file") || warn "Can't open $ck_file: $!\n";
  foreach $line (<F>) {
    next if $line =~ /^#|^$/;
    chomp($line);
    $line =~ s/\s+//g;
    $line =~ s/[^[:alnum:]]//g;
    $file_string .= "$line";
  }
  close(F);

  chomp($sumval = `echo \"${file_string}\" | /bin/sum`);
  print "\"${key}\": \"$ck_file = $sumval\"\n";

}


sub get_mounted_nas {
  my ($key) = @_;

  $cmd_ok = 0;

  open(cmd, "$timeout /bin/df -hP 2>/dev/null |") || warn "Can't run df: $!\n";
  foreach $mount (<cmd>) {

    chomp($mount);

    next unless $mount =~ /[a-z]:\/[a-z]/i;
    next if $mount =~ /\.snapshot/;

    $mount =~ s/\s+/ /g;

    print "\"${key}\": \"$mount\"\n";
    $cmd_ok = 1;

  }
  close(cmd);

  if ( $cmd_ok == 0 ) {
    print "\"${key}\": \"command timed out\"\n";
  }

}


sub get_file_contents {
  my ($key, $con_file) = @_;

  if ( -f "$con_file") {
    chomp($lstime = `ls -l $con_file`);
    print "\"${key}\": \"$lstime\"\n";

    open(F, "< $con_file") || warn "Can't open $con_file: $!\n";
    foreach $line (<F>) {
      chomp($line);
      if ($con_file !~ /\/etc\/passwd|\/etc\/group/) {
        next if $line =~ /^#|^$/;
      }
      print "\"${key}\": \"$line\"\n";
    }
    close(F);
  } else {
    print "\"${key}\": \"$con_file not found\"\n";
  }

}


sub grpck_fix_mode {
  my ($key) = @_;

  chomp($stdout = `/bin/echo 'y' | $timeout /usr/sbin/grpck 2>&1`);

  if ( $stdout =~ /[a-z]/i ) {
    foreach $line (split(/\n/, $stdout)) {
      print "\"${key}\": \"$line\"\n";
      $cmd_ok = 1;
    }
  } else {
    print "\"${key}\": \"No fixes required\"\n";
  }

}


sub grpck_report_mode {
  my ($key) = @_;

  chomp($stdout = `$timeout /usr/sbin/grpck -r 2>&1`);

  if ( $stdout =~ /[a-z]/i ) {
    foreach $line (split(/\n/, $stdout)) {
        print "\"${key}\": \"$line\"\n";
    }
  } else {
    print "\"${key}\": \"No problems reported\"\n";
  }

}


sub pwdck_fix_mode {
  my ($key) = @_;

  chomp($stdout = `/bin/echo 'y' | $timeout /usr/sbin/pwck -q 2>&1`);

  if ( $stdout =~ /[a-z]/i ) {
    foreach $line (split(/\n/, $stdout)) {
        print "\"${key}\": \"$line\"\n";
    }
  } else {
    print "\"${key}\": \"No fixes required\"\n";
  }

}


sub pwdck_report_mode {
  my ($key) = @_;

  chomp($stdout = `$timeout /usr/sbin/pwck -qr 2>&1`);

  if ( $stdout =~ /[a-z]/i ) {
    foreach $line (split(/\n/, $stdout)) {
        print "\"${key}\": \"$line\"\n";
    }
  } else {
    print "\"${key}\": \"No problems reported\"\n";
  }

}


sub get_qpm_rpm {
  my ($key) = @_;

  open(RPM, "$timeout /usr/bin/rpm -qa |");
  foreach $line (<RPM>) {
    chomp($line);
    if ( $line =~ /qpm.*agent|qpm.*server/ ) {
      print "\"${key}\": \"${line}\"\n";
    }
  }
  close(RPM);

}


sub get_install_date {
  my ($key) = @_;

  open(RPM, "$timeout /usr/bin/rpm -qi filesystem |");
  foreach $line (<RPM>) {
    chomp($line);
    if ( $line =~ /Install Date/ ) {
      $line =~ s/Install Date: //g;
      print "\"${key}\": \"${line}\"\n";
    }
  }
  close(RPM);

}


sub count_secure_entries() {

  $pmrun_ct = 0;
  $sudo_ct = 0;

  $epoch = time;
  $yesterday = strftime('%b %e', localtime(mktime(localtime(time-(86400)))));

  chdir("/var/log");
  opendir(DIR, ".");
  foreach $file (readdir(DIR)) {
    next unless $file =~ /secure/;
    $filetime = (stat($file))[9];
    next unless ($epoch - $filetime < 86400 * 7);
    open(ZG, "/bin/zgrep \"$yesterday\" $file |");
    foreach $line (<ZG>) {
      chomp($line);
      next unless $line =~ /session opened for user/;
      if ( $line =~ /pmrun/ ) {
        $pmrun_ct++;
      }
      if ( $line =~ /sudo/ ) {
        $sudo_ct++;
      }
    }
  }
  closedir(DIR);

  print "\"PMRUN_CT\": \"${pmrun_ct}\"\n";
  print "\"SUDO_CT\": \"${sudo_ct}\"\n";

}


sub sudo_files {
  my ($key) = @_;

  if ( -f "/etc/sudoers" ) {
    calculate_sum($key, "/etc/sudoers");
    get_file_contents("SUDO", "/etc/sudoers");
  }

  chdir("/etc/sudoers.d");
  opendir(DIR, ".");
  foreach $file (readdir(DIR)) {
    next if $file =~ /^\./;
    calculate_sum($key, "/etc/sudoers.d/$file");
    get_file_contents("SUDO", "/etc/sudoers.d/$file");
  }
  closedir(DIR);

}


sub list_directory_contents {
  my ($key, $listdir) = @_;

  if ( -d "$listdir" ) {
    foreach $file (`ls -ltr $listdir`) {
      next if $file =~ /^total/;
      chomp($file);
      $file =~ s/\s+/ /g;
      print "\"$key\": \"$file\"\n";
    }
  } else {
    print "\"$key\": \"$listdir not found\"\n";
  }

}



########## main ##########

# SUM of current script
calculate_sum("SCANSUM", "$0");

# NFS Mounts
get_mounted_nas("NASMNT");

# File Contents
get_file_contents("GROUP", "/etc/group");
get_file_contents("PASSWD", "/etc/passwd");
get_file_contents("SSSD", "/etc/sssd/sssd.conf");
get_file_contents("VAS", "/etc/opt/quest/vas/vas.conf");
get_file_contents("LASTJOIN", "/etc/opt/quest/vas/lastjoin");
get_file_contents("PMUL", "/etc/opt/quest/qpm4u/pm.settings");
get_file_contents("USERSALLOW", "/etc/opt/quest/vas/users.allow");
get_file_contents("OSVERSION", "/etc/redhat-release");

# File Checks
grpck_fix_mode("GROUPCHECK");
grpck_report_mode("GROUPCHECK");
pwdck_fix_mode("PASSWDCHECK");
pwdck_report_mode("PASSWDCHECK");

# RPM-Derived Data
get_qpm_rpm("QPMRPM");
get_install_date("INSTALLDATE");

# Secure File Counts
count_secure_entries();

# Sudo file sums and contents
sudo_files("SUDOSUM");

# Directory Listings
list_directory_contents("LOCALBIN", "/usr/local/bin");
list_directory_contents("PROFILES", "/etc/profile.d");
list_directory_contents("RSYSLOG", "/etc/rsyslog.d");

exit(0);
