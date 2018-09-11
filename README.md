# tarcreater

### Running the tarcreater manually

```
python tarcreater.py -p <omics-ratio.gct> -e <experiment-design.csv> -o <output.tar> [ (optional) -m <extra_file_1> <extra_file_2> ...]

Rscript tarcreater.r 
-p <omics-ratio.ext>
-e <experiment-design.csv>
-o <output.tar>
-f gct/cct/... (extension)
-v 1.2/1.3 (version)
-m <extra_file1> <Extra_File_2> ... (optional files)
```

### Running the tarcreater on Firecloud

1. Use `java -jar wdltool.jar inputs ...` to generate `inputs.json` file (see a sample in the `wdl/pgdac_skip_parse` folder)
2. Edit the `inputs.json` file to remove the optional parameters that you don't want to enter. Edit the required fields to match your inputs.
3. Use `java -jar cromwell.jar run ...` to execute the `wdl/pgdac_skip_parse/pgdac_skip_parse.wdl` with the `--inputs` parameter set to the `inputs.json` file created above.

### Outputs

Tar file extracts to two directories - `data` and `parsed-data`. `data` houses the `experiment-design.csv` file. `parsed-data` contains the required `<omics-ratio.gct` and extra optional files passed through the `-m` option or through the *extra* field in the `inputs.json` file as ["extra_file_1", "extra_file_2", ...].

For queries mail:
rkothadi@broadinstitute.org
