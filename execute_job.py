import pdb
import subprocess
import shlex
import sys
import os
import errno

files = {'ERR': "jobs.err", 'LOG': "jobs.log"}

def execute_job(commParams, filepointers=None):
    command = ' '.join(commParams)
    if filepointers == None:
        filepointers = {}
    if 'ERR' not in filepointers:
        filepointers['ERR'] = open(files['ERR'], 'a+')
    if 'LOG' not in filepointers:
        filepointers['LOG'] = open(files['LOG'], 'a+')
    try:
        thread0 = subprocess.Popen( shlex.split(command), stdout = subprocess.PIPE, stderr = filepointers['ERR'])
        thread0.wait()
        logstring = command + "\nSuccessful.\n"
        filepointers['LOG'].write(logstring)
        return thread0.stdout.read()
    except subprocess.CalledProcessError as err:
        logstring = "\nError::\n" + err.output
        filepointers['LOG'].write(logstring)
        exit()
    except Exception as E:
        logstring = str(E)
        filepointers['LOG'].write(logstring)
        for filepointer in filepointers:
            filepointers[filepointer].close()

def main():
    command = sys.argv[1]
    commParams = command.split()
    result = execute_job(commParams).strip()
    #pdb.set_trace()
    print(result)

if __name__ == "__main__":
    main()
