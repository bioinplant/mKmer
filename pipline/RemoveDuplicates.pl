#!/usr/bin/perl
#!/usr/bin/perl
use warnings;
use Getopt::Long;

my $usage = qq{
This script takes an input FASTQ file (formatted with four lines per sequence) and removes duplicate entries based on ID,
keeping the sequence with the highest average quality score.
Usage:
perl $0 -i <path for input file> -o <output file name>
};

my $infile;
my $outfile;
GetOptions(
    "i=s" => \$infile,
    "o=s" => \$outfile,
) or die $usage;
die $usage unless defined $infile;
die $usage unless defined $outfile;

open(my $IN, "gzip -dc $infile |") or die "Unable to open $infile\n";
open(my $OUT, ">", $outfile) or die "Unable to open file for output.\n";  # Open the output file as specified

my %seqs;
while (my $line1 = <$IN>) {
    my $line2 = <$IN>;
    my $line3 = <$IN>;
    my $line4 = <$IN>;

    chomp $line1;
    my $id = substr($line1, -29); # Extract the last 29 characters
    my $quality = substr($line4, 0, -1);
    my $avg_quality = avg_quality_score($quality);

    if (exists $seqs{$id}) {
        if ($avg_quality > $seqs{$id}{quality}) {
            $seqs{$id} = { seq => $line1 . "\n" . $line2 . $line3 . $line4, quality => $avg_quality };
        }
    } else {
        $seqs{$id} = { seq => $line1 . "\n" . $line2 . $line3 . $line4, quality => $avg_quality };
    }
}

foreach my $id (keys %seqs) {
    print $OUT $seqs{$id}{seq};
}

close $IN;
close $OUT;
print "Sequences with the highest quality scores have been written to $outfile\n";  # Modify the output message

sub avg_quality_score {
    my ($quality) = @_;
    my $total = 0;
    my $count = length($quality);
    return 0 if $count == 0;  # Avoid division by zero
    for my $char (split //, $quality) {
        $total += ord($char) - 33;
    }
    return $total / $count;
}
