import execute_job
import sys
import os
import pdb
import cmapPy.pandasGEXpress.parse as parse_gct

os.environ["TF_CPP_MIN_LOG_LEVEL"]="3"
args = {}

def set_arguments():
    global set_arguments
    valid = ['p', 'e', 'o', 'm']
    arglen = len(sys.argv)
    index = 1
    while (index < arglen and sys.argv[index][1:] != 'm'):
        option = sys.argv[index]
        if option[0] == '-' and option[1:] in valid:
            args[option[1:]] = sys.argv[index+1]
            index += 2
        elif option[0] == '-' and option[1:] not in valid:
            print("# Error: Invalid Option.\n")
            usage()
            sys.exit(1)
        else:
            pass
    while (index < arglen):
        if 'm' not in args:
            args['m'] = []
        else:
            args['m'].append(sys.argv[index])
        index += 1
    if 'p' not in args or 'o' not in args:
        print("\n# ERROR: -p/-o required.")
        usage()
        sys.exit(1)


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
    \n\t -e <experiment-design-file> \
    \n\t -o <output tar file> \
    \n\t [-m (optional field) <extra_file_1> <extra_file_2> ...]")

def create_tar():
    tardir = args['o'].split('.')[0]
    commParamArr = []
    commParamArr.append([ 'mkdir', tardir ])
    commParamArr.append([ 'mkdir', tardir + "/data" ])
    commParamArr.append([ 'mkdir', tardir + "/parsed-data" ])
    commParamArr.append([ 'cp', args['e'], tardir + "/data/" ])
    commParamArr.append([ 'cp', args['p'], tardir + "/parsed-data/" ])
    if 'm' in args:
        for extra in args['m']:
            commParamArr.append(['cp'] + [extra] + [tardir + "/parsed-data/"])
    commParamArr.append([ 'tar', '-cvf', args['o'], tardir ])
    commParamArr.append([ 'rm', '-rf', tardir])
    for commParams in commParamArr:
        allok = execute_job.execute_job(commParams)
        if not allok:
            print("\n# ERROR: Aborting this program.")
            sys.exit(1)

def check_gct_against_expt(myfile):
    out = parse_gct.parse(myfile)
    print(out.version)
    if out.version == "GCT1.2":
        if 'e' not in args:
            usage()
            sys.exit(1)
    cid = out.col_metadata_df.index
    ecid, emeta = extract_expt_desn()
    if len(ecid) < len(cid):
        print("# Error: Samples in .GCT not found in EXPT DESN file.")
        sys.exit(1)
    elif len(ecid) > len(cid):
        print "# WARNING: Some Samples Missing in", myfile, "file."
    else:
        pass

def stub(myfile):
    pass

def check_format(myfile):
    ext = myfile.split('.')[-1]
    options = {
        'gct' : check_gct_against_expt,
        'cct' : stub
    }
    options[ext](myfile)

def main():
    pdb.set_trace()
    set_arguments()
    check_format(args['p'])
    create_tar()

if __name__ == "__main__":
    main()
