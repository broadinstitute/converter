task pgdac_skip_parse {
  File omicsRatio
  File exptDesign
  String outFile = "pgdac_skip_parse-output.tar"
  Array[File] extra

  Int? memory
  Int? disk_space
  Int? num_threads
  Int? num_preemptions

  command {
    set -euo pipefail
    python /prot/proteomics/Projects/PGDAC/src/tarcreater/tarcreater.py -p ${omicsRatio} -e ${exptDesign} -o ${outFile} -m ${sep=' ' extra}
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
