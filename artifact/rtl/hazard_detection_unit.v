module hazard_detection_unit #(
  parameter CORE            = 0,
  parameter ADDRESS_BITS    = 20,
  parameter SCAN_CYCLES_MIN = 0,
  parameter SCAN_CYCLES_MAX = 1000
) (
  input clock,
  input reset,

  input fetch_valid,
  input fetch_ready,
  input issue_request,
  input [ADDRESS_BITS-1:0] issue_PC,
  input [ADDRESS_BITS-1:0] fetch_address_in,
  input memory_valid,
  input memory_ready,

  input load_memory,
  input store_memory,
  input [ADDRESS_BITS-1:0] load_address,
  input [ADDRESS_BITS-1:0] memory_address_in,

  input [6:0] opcode_decode,
  input [6:0] opcode_execute,
  input branch_execute,

  output i_mem_hazard,
  output d_mem_hazard,
  output JALR_branch_hazard,
  output JAL_hazard,

  input scan
);

localparam [6:0]R_TYPE  = 7'b0110011,
                BRANCH  = 7'b1100011,
                JALR    = 7'b1100111,
                JAL     = 7'b1101111;


// Instruction/Data memory hazard detection
assign i_mem_hazard = (~fetch_ready & ~issue_request) |
                      (issue_request & (~fetch_valid  | (issue_PC != fetch_address_in)));

assign d_mem_hazard = ~memory_ready |
                      (load_memory & (~memory_valid |
                      (load_address != memory_address_in)));

// JALR BRANCH and JAL hazard detection
// JALR_branch and JAL hazard signals are high when there is a control flow
// change caused by one of these instructions. These signals are present in
// both pipelines and unpipelined versions of the processor.
assign JALR_branch_hazard = (opcode_execute == JALR  ) |
                            ((opcode_execute == BRANCH) & branch_execute);

assign JAL_hazard         = (opcode_decode == JAL);


/* pk
reg [31: 0] cycles;
always @ (posedge clock) begin
  cycles <= reset? 0 : cycles + 1;
  if (scan  & ((cycles >= SCAN_CYCLES_MIN) & (cycles <= SCAN_CYCLES_MAX)) )begin
    $display ("------ Core %d Hazard Detection Unit - Current Cycle %d ------", CORE, cycles);

    $display ("| Fetch Valid        [%b]", fetch_valid);
    $display ("| Fetch Ready        [%b]", fetch_ready);
    $display ("| Issue Request      [%b]", issue_request);
    $display ("| Issue PC           [%h]", issue_PC);
    $display ("| Fetch Address In   [%h]", fetch_address_in);
    $display ("| Load Memory        [%b]", load_memory);
    $display ("| Memory Valid       [%b]", memory_valid);
    $display ("| Store Memory       [%b]", store_memory);
    $display ("| Memory Ready       [%b]", memory_ready);
    $display ("| I-Mem Hazard       [%b]", i_mem_hazard);
    $display ("| D-Mem Hazard       [%b]", d_mem_hazard);
    $display ("| JALR/branch Hazard [%b]", JALR_branch_hazard);
    $display ("| JAL Hazard         [%b]", JAL_hazard);
    $display ("----------------------------------------------------------------------");
  end
end
*/

endmodule
