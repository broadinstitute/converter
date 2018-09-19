task pgdac_skip_parse {
  File omicsRatio
  String fileType
  String dataType
  File rna
  File cna
  String outFile = "pgdac_skip_parse-output.tar"
  String? tumorAnnot
  File? exptDesign
  Array[File]? extra
  String? version
  String? normalize

  Int? memory
  Int? disk_space
  Int? num_threads
  Int? num_preemptions

  command {
    set -euo pipefail
    R CMD BATCH --vanilla "--args -p ${omicsRatio} -f ${fileType} -dt ${dataType} -rna ${rna} -cna ${cna} -o ${outFile} -v ${version} -e ${exptDesign} -t ${tumorAnnot} -n ${normalize} -m ${sep=' ' extra}" /prot/proteomics/Projects/PGDAC/src/tarcreater.r
  }

  output {
    File outputs = "${outFile}"
  }

  runtime {
    docker : "rkothadi/pgdac_skip_parse:1"
    memory : select_first ([memory, 4]) + "GB"
    disks : "local-disk " + select_first ([disk_space, 5]) + " SSD"
    cpu : select_first ([num_threads, 1]) + ""
    preemptible : select_first ([num_preemptions, 0])
  }

  meta {
    author : "Ramani Kothadia"
    email : "rkothadi@broadinstitute.org"
  }
}


workflow pgdac_skip_parse_workflow {
	call pgdac_skip_parse
}
