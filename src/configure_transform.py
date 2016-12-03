#!/usr/bin/env python

import os
import re
import sys
sys.path.append('../libexec/python')

from utils import check_exists
from logman import logger
import argparse

define_re = re.compile("#define ([A-Z_]+) (.*)")

# ../src/lib/config_defaults.h singularity.conf.in singularity.conf

defaultfile = open(sys.argv[1], "r")
infile = open(sys.argv[2], "r")
outfile = open(sys.argv[3] + ".tmp", "w")

data = infile.read()

defaults = {}
for line in defaultfile:
    m = define_re.match(line)
    if m:
        key, value = m.groups()
        defaults[key] = value

for key, value in defaults.items():
    new_value = value.replace('"', '')
    if new_value == "1":
        new_value = "yes"
    elif new_value == "0":
        new_value = "no"
    data = data.replace("@" + key + "@", new_value)

outfile.write(data)
outfile.close()
os.rename(sys.argv[3] + ".tmp", sys.argv[3])



def get_parser():

    parser = argparse.ArgumentParser(description="singularity configuration parsing helper in python")

    # Configuration defaults header
    parser.add_argument("--defaults", 
                        dest='defaults', 
                        help="configuration defaults header file (../src/lib/config_defaults.h)", 
                        type=str, 
                        required=True)

    # input configuration file
    parser.add_argument("--infile", 
                        dest='infile', 
                        help="the configuration input file path (singularity.conf.in)", 
                        type=str, 
                        required=True)

    # Output configuration file
    parser.add_argument("--outfile", 
                        dest='outfile', 
                        help="the configuration output file path (singularity.conf)", 
                        type=str, 
                        required=True)

    return parser


def main():
    '''main is a wrapper for the client to hand the parser to the executable functions
    This makes it possible to set up a parser in test cases
    '''
    logger.info("\n*** STARTING PYTHON CONFIGURATION HELPER ****")
    parser = get_parser()
    
    try:
        args = parser.parse_args()
    except:
        logger.error("Input args to %s improperly set, exiting.", os.path.abspath(__file__))
        parser.print_help()
        sys.exit(0)

    # Run the configuration
    configure(args)


def configure(args):

    # Find root filesystem location
    if args.rootfs != None:
       singularity_rootfs = args.rootfs
       logger.info("Root file system defined by command line variable as %s", singularity_rootfs)
    else:
       singularity_rootfs = os.environ.get("SINGULARITY_ROOTFS", None)
       if singularity_rootfs == None:
           logger.error("root file system not specified OR defined as environmental variable, exiting!")
           sys.exit(1)
       logger.info("Root file system defined by env variable as %s", singularity_rootfs)

    # Does the registry require authentication?

        logger.info("*** FINISHING DOCKER BOOTSTRAP PYTHON PORTION ****\n")


if __name__ == '__main__':
    main()
