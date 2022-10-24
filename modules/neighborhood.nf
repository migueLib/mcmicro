import mcmicro.*
include {worker} from "$projectDir/lib/worker"

// Define misty process
process misty {
  // Load Modules
  container "${params.contPfx}${module.container}:${module.version}"

  // Output directories
  publishDir "${params.in}/mistyr/results", mode: 'copy', pattern: "*.txt"
  publishDir "${params.in}/mistyr/figures", mode: 'copy', pattern: "*.pdf"

  // Logs and provenance
  publishDir "${Flow.QC(params.in, 'provenance')}", mode: 'copy', 
    pattern: '.command.{sh,log}',
    saveAs: {fn -> fn.replace('.command', "${module.name}-${task.index}")}

    // Process input
    input:
      val mcp
      val module
      path code
      path sft
      path marker

    // Process output
    output: 
      path("*.txt"), emit: results
      path("*.pdf"), emit: figures
      tuple path('.command.sh'), path('.command.log')
    // I'm not sure what's this for
    when: 
      mcp.workflow["mistyr"]
    // Actual code 
    """
    /usr/local/bin/Rscript --vanilla $code $sft $marker . . 
    """

}


workflow mistyr {
  take:
    mcp
    sft
    marker

  main:
    code = Channel.fromPath("$projectDir/misty/misty_wrapper.R")
    misty(mcp, mcp.modules["mistyr"], code, sft, marker)

  emit:
    misty.out.results
    misty.out.figures
}
