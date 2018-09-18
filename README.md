# tarcreater

### Running the tarcreater manually

Rscript tarcreater.r [OPTIONS]


| OPTIONS | VALUES | REQUIRED | DESCRIPTION |
|:-------:|:------:|:--------:|-------------|
| -p | `omics-ratio.ext`                              | REQUIRED                                  | -omics input File |
| -f | `ext`                                          | REQUIRED                                  | File extension of `-p`; Can be: `gct`, `cct`. |
| -v | 1.2/1.3                                        | REQUIRED for `gct`                        | version of `-p` if `gct` |
| -e | `experiment-design.csv` / `your-file-name.tsi` | REQUIRED if `-p` is `gct` and `-v` is 1.2 | Allowed pairs: `csv-gct` and `tsi-cct`|
| -o | `output.tar`                                   | REQUIRED                                  | No absolute paths; Only output tarball name |
| -n | normalized flag                                | REQUIRED                                  | `T` if normalized; `F` otherwise |
| -t | annotation flag                                | OPTIONAL                                  | `T` if -omics data contains `.T`/`.N` suffixed sample IDs/column names; `F` otherwise |
| -m | `extra_file_1` `extra_file_2` ...              | OPTIONAL                                  | In presence of `sct` file, make it the first argument to this option |

```
python tarcreater.py [OPTIONS] ***OBSOLETE***

OPTIONS:
-p <omics-ratio.gct> -REQUIRED-
-e <experiment-design.csv> -REQUIRED-
-o <output.tar> -REQUIRED-
-m <extra_file_1> <extra_file_2> ... -OPTIONAL-

```

### Running the tarcreater on Firecloud

1. Use `java -jar wdltool.jar inputs ...` to generate `inputs.json` file (see a sample in the `wdl/pgdac_skip_parse` folder)
2. Edit the `inputs.json` file to remove the optional parameters that you don't want to enter. Edit the required fields to match your inputs.
3. Use `java -jar cromwell.jar run ...` to execute the `wdl/pgdac_skip_parse/pgdac_skip_parse.wdl` with the `--inputs` parameter set to the `inputs.json` file created above.

### Outputs

Tar file extracts to two directories - `data` and `parsed-data`. `data` houses the `experiment-design.csv` file. `parsed-data` contains the required `<omics-ratio.gct` and extra optional files passed through the `-m` option or through the *extra* field in the `inputs.json` file as ["extra_file_1", "extra_file_2", ...].

For queries mail:
rkothadi@broadinstitute.org
