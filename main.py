import execute_job
import sys
import os
import cmapPy.pandasGEXpress.parse as parse_gct

os.environ["TF_CPP_MIN_LOG_LEVEL"]="3"
args = {}

def set_arguments():
    global args
    valid = ['p', 'c', 'r', 'h', 'e']
    arglen = len(sys.argv)
    for idx in range(1, arglen):
        option = sys.argv[idx]
        if option[0] == '-' and option[1:] in valid :
            args[option[1:]] = sys.argv[idx+1]
        if option[0] == '-' and option[1:] not in valid:
            print("# Error: Invalid Option.\n")
            usage()

def extract_expt_desn():
    fp = open(args['e'], 'r')
    meta = fp.readline().strip().split(',')
    samples = fp.readlines()
    cdesc = {}
    for sample in samples:
        sample = sample.strip().split(',')
        cdesc[sample[0]] = sample[1:]
    fp.close()
    return cdesc, meta

def usage():
    print("\nUsage: python main.py \
    \n\t -p <ome-file> \
    \n\t -r <rna-file> \
    \n\t -c <cna-file> \
    \n\t -e <experiment-design-file> \
    \n\t [-h for help]")

def create_tar():
    commParams = [             'tar', \
                              '-cvf', \
                   "parseInputs.tar", \
                           args['p'], \
                           args['r'], \
                           args['c']  ]
    execute_job.execute_job(commParams)

def check_gct_against_expt(myfile):
    out = parse_gct.parse(myfile)
    cid = out.col_metadata_df.index
    ecid, emeta = extract_expt_desn()
    if len(ecid) < len(cid):
        print("# Error: Samples in .GCT not found in EXPT DESN file.")
        sys.exit(1)
    elif len(ecid) > len(cid):
        print "# WARNING: Some Samples Missing in", myfile, "file."
    else:
        pass

def main():
    set_arguments()
    check_gct_against_expt(args['p'])
    check_gct_against_expt(args['r'])
    check_gct_against_expt(args['c'])
    create_tar()

if __name__ == "__main__":
    main()
