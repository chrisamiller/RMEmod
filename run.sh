#!/bin/bash

wModDir=$(dirname "$0")
export RUBYLIB=$RUBYLIB:$wModDir

function usage
{
    echo ""
    echo "usage: wmod -i <infile> -s <modSize> -g <numGenes> -o <outdir>"
    echo ""
    echo "  -s | --maxModSize  max module size (required)"
    echo "  -i | --infile      input matrix (required)"
    echo "  -g | --genes       total number of genes assayed (required)"
    echo "  -o | --outFile1    list of potential modules"
    echo "  -p | --outfile2    best modules (chosen by pickModules)"
    echo "  -b | --bgrate      background mutation rate (optional - default 13.0)"
    echo "  -w | --threshold   winnow score threshold (optional - default 4.0)"
    echo "  -m | --minFreq     minimum freq of genes considered (optional - default 0.10)"
    echo "  -t | --sigThresh   significance threshold (optional - default 50)"
    echo "  -q | --quiet       less stderr output, for unsupervised use"
    echo "  -h | --help        output usage"
    echo ""
    echo "see README for more information"
    echo ""
    exit 1
}


if [[ "$1" == "" ]];then
    usage
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -s | --maxModSize )     shift
                                maxModSize=$1
                                ;;
        -i | --infile )         shift
                                infile=$1
				;;
        -w | --threshold )      shift
                                winThresh=$1
				;;
        -m | --minFreq )        shift
                                minFreq=$1
				;;
        -o | --outfile1 )       shift
                                outfile1=$1
				;;
        -p | --outfile2 )       shift
                                outfile2=$1
				;;
        -g | --genes )          shift
                                genes=$1
				;;
        -t | --sigThresh )      shift
                                sigThresh=$1
				;;
        -b | --bgrate )         shift
                                bgrate=$1
				;;
        -q | --quiet )          verbose="false"
				;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

#check params for presence/sanity
if [[ "$maxModSize" == "" ]]; then
    echo "ERROR: maxModSize required"
    exit 1
fi

if [[ "$outfile1" == "" ]]; then
    echo "ERROR: outfile1 required"
    exit 1
fi

if [[ "$outfile2" == "" ]]; then
    echo "ERROR: outfile2 required"
    exit 1
fi

if [[ "$genes" == "" ]]; then
    echo "ERROR: number of genes assayed required"
    exit 1
fi

if [[ "$bgrate" == "" ]]; then
    bgrate=0.010372
fi

if [[ "$sigThresh" == "" ]]; then
    sigThresh=50
fi

if [[ "$winThresh" == "" ]]; then
    winThresh=4.0
fi

if [[ "$minFreq" == "" ]]; then
    minFreq=0.10
fi

if [[ "$outdir" == "" ]]; then
    outdir=.
fi

#echo params
if [[ "$verbose" != "false" ]];then
  echo "infile:     $infile"
  echo "outfile1:   $outfile1"
  echo "outfile2:   $outfile2"
  echo "maxModSize: $maxModSize"
  echo "threshold:  $winThresh"
  echo "minFreq:    $minFreq"
  echo "bgrate:     $bgrate"
  echo "winThresh:  $winThresh"
fi

#make the output directory if it doesn't exist
# mkdir $outdir 2>/dev/null

if [[ "$verbose" != "false" ]];then
  echo "Generating Network..."
fi


# run winnow to generate exclusivity scores
ruby $wModDir/xorWinnow.rb $infile $minFreq $winThresh >network.dat


#search the network for RME modules
if [[ "$verbose" != "false" ]];then
  echo "Searching the Network..."
  ruby $wModDir/depthOneSearch.rb $infile network.dat 2 $maxModSize $genes $minFreq $bgrate | sort -nrk 1 >$outfile1
else
  ruby $wModDir/depthOneSearch.rb $infile network.dat 2 $maxModSize $genes $minFreq $bgrate false | sort -nrk 1 >$outfile1
fi


#filter the potential modules and keep the largest, best scoring ones
ruby $wModDir/pickModules.rb $outfile1 $infile $sigThresh >$outfile2


