#!/usr/bin/perl
########################################################################
#
#     Scriptname:  hexconv.pl
#         Author:  Samuel Januario (samuel.januario01@gmail.com)
#    Create Date:  June 18, 2013
#        Purpose:  Call script with argument to convert entered HEX time 
#					to full timestamp 
#
########################################################################
if (!@ARGV[0]) { print ("Usage: hexconv.pl <HEX Date>\n"); exit(1); }
$v=hex($ARGV[0]);

print &translate_time($v);

exit 0;

#----------------------------------------------------------------------------------
sub translate_time {
#----------------------------------------------------------------------------------
        local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdat)=localtime($_[0]);
        local($month,$date);
        $hour="0$hour" if (length($hour)==1);
        $min="0$min" if (length($min)==1);
        $sec="0$sec" if (length($sec)==1);

        $year+=1900;

        $month=(Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$mon];
        $date="$month $mday $year $hour:$min:$sec\n";
        return $date;
}
