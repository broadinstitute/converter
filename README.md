# tarcreater

### Running the tarcreater manually

`python tarcreater.py -p <omics-ratio .GCT file> -e <experiment-design .CSV file> -o <output.tar> [ (optional) -m <extra_file_1> <extra_file_2> ...]`

### Running the tarcreater on Firecloud

1. Use `wdltool`'s 'inputs' to generate `<inputs.json>` file (see a sample in the wdl/pgdac_skip_parse folder)
2. Edit the `<inputs.json>` file to remove the optional parameters that you don't want to enter and to edit the required fields according to your requirements.
3. Use `cromwell`'s 'run' to execute the `wdl` file in the `wdl/pgdac_skip_parse/` folder with the `--inputs` parameter set to the `<inputs.json>` file created above.

### Outputs

After extracting the output tar file you can see that there exist two directories:

1. `data`
2. `parsed-data`

`data` houses the `experiment-design.csv` file. Whereas, the  `parsed-data` houses the required `<omics-ratio .GCT file` and extra optional files passed through the `-m` option or through the *extra* field in the `<inputs.json>` file as ["extra_file_1", "extra_file_2", ...].

For queries mail:
rkothadi@broadinstitute.org 
