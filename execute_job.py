import pdb
import subprocess
import shlex
import sys
import os
import errno

files = {'LOG': "jobs.log"}

def execute_job(commParams, filepointers=None):
    if filepointers == None:
        filepointers = {}
    if 'LOG' not in filepointers:
        filepointers['LOG'] = open(files['LOG'], 'a+')
    command  = ' '.join(commParams)
    errormsg = ""
    try:
        thread0 = subprocess.Popen( shlex.split(command), stdout = subprocess.PIPE, stderr = filepointers['LOG'] )
        thread0.wait()
        #print thread0.stdout.read().strip(),
        return True
    except subprocess.CalledProcessError as err:
        errormsg = "\n# ERROR: " + err.output
    except Exception as E:
        errormsg += "\n# ERROR: " + str(E)
    filepointers['LOG'].write(errormsg)
    for filepointer in filepointers:
        filepointers[filepointer].close()
    return False

def main():
    command = sys.argv[1]
    commParams = command.split()
    result = execute_job(commParams).strip()
    #pdb.set_trace()
    print(result)

if __name__ == "__main__":
    main()
