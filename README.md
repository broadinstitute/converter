# File Converter

### Usage

```
R CMD BATCH --vanilla "--args
--inputfile $inputFile
--inputtype $inputType
--targettype $targetType
--targetfile $targetFile
--datatype $dataType
--coerce [...]" converter.R


Usage: %prog [options]

Options:
     -i <inputFile>, --inputfile=<inputFile>
         Please Provide Absolute Paths

     -a <inputType>, --inputtype=<inputType>
         Supported Types: cct, cdap

     -b <targetType>, --targettype=<targetType>
         Supported Types: gct

     -o <targetFile>, --targetfile=<targetFile>
         Please provide absolute paths

     -d <dataType>, --datatype=<dataType>
         Supported Data Types: Proteome, Phosphoproteome

     -e <experimentDesignFile>, --exptdesign=<experimentDesignFile>
         Please provide absolute paths. Supported types: csv, .tsi.xlsx, .txt

     -c , --coerce
         If you want to forcefully match the input file with experiment design file by removing samples not found in -exptdesign.

     -t, --tumorannot
         If samples are annoted with .T/.N.

     --log=<log base>
         Base of log transform on the input data.

     --sct=<sctFile>
         sct File

     -h, --help
         Show this help message and exit
```

### Running the tarcreater on Firecloud

1. Use `java -jar wdltool.jar inputs ...` to generate `inputs.json` file (see a sample in the `wdl/pgdac_skip_parse` folder)
2. Edit the `inputs.json` file to remove the optional parameters that you don't want to enter. Edit the required fields to match your inputs.
3. Use `java -jar cromwell.jar run ...` to execute the `wdl/pgdac_skip_parse/pgdac_skip_parse.wdl` with the `--inputs` parameter set to the `inputs.json` file created above.

For queries mail:
rkothadi@broadinstitute.org
