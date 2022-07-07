module aes_top (
    input clk,
    input resetn,
    input valid,
    input wen,
    input [23:0] addr,
    input [31:0] wdata,
    output [31:0] rdata,
    output ready
);
 
    //---------------------------------------------------//
    //--------Software accessible Register space---------//     
    //---------------------------------------------------//
    localparam CTRL_ADDR  = 32'h00000000,  // Control register
               KEYW0_ADDR = 32'h00000004,  // Key word 0
               KEYW1_ADDR = 32'h00000008,  // Key word 1
               KEYW2_ADDR = 32'h0000000C,  // Key word 0 
               KEYW3_ADDR = 32'h00000010,  // Key word 0 
               PTW0_ADDR = 32'h00000014,   // PT word 0
               PTW1_ADDR = 32'h00000018,   // PT word 1
               PTW2_ADDR = 32'h0000001C,   // PT word 2
               PTW3_ADDR = 32'h00000020,   // PT word 3
               IVW0_ADDR = 32'h00000024,   // IV word 0
               IVW1_ADDR = 32'h00000028,   // IV word 1
               IVW2_ADDR = 32'h0000002C,   // IV word 2
               IVW3_ADDR = 32'h00000030,   // IV word 3
               CTW0_ADDR = 32'h00000034,   // CT word 0
               CTW1_ADDR = 32'h00000038,   // CT word 1
               CTW2_ADDR = 32'h0000003C,   // CT word 2
               CTW3_ADDR = 32'h00000040,   // CT word 3
               STATUS_ADDR = 32'h00000044; // Status reg

    // Bit positions in Control Reg
    localparam CTRL_SOFT_RST_BIT = 0,
               CTRL_INPUTS_VALID_BIT = 1,
               CTRL_ENCDEC_BIT = 2,
               CTRL_AESMODE_LSB = 3,
               CTRL_AESMODE_MSB = 4,
               CTRL_REG_SIZE = CTRL_AESMODE_MSB+1;
    // AES Mode
    localparam AES_MODE_ECB = 2'b00,
               AES_MODE_CBC = 2'b01;

    reg [127:0] key_reg;    // AES Key
    reg [127:0] input_block_reg;     // Plaintext block
    reg [127:0] iv_reg_initial; // IV   
    reg [127:0] output_block_reg;     // Ciphertext block
    
    reg soft_rst_reg;       // Soft Reset
    reg inputs_valid_reg;   // All inputs have been given
    reg encdec_reg;         // Encode/Decode select
    reg [1:0] aes_mode_reg; // 00 - ECB, 01 - CBC
    reg output_ready_reg;   // CT result is ready

    // AES Core signals
    reg core_init;
    reg core_next;
    wire core_rstn;
    wire core_encdec;
    wire core_ready;
    wire [127:0] core_key;
    wire core_keylen;
    wire [127:0] core_block;
    wire [127:0] core_result;
    wire core_result_valid;

    // New key indicator
    // This is an internal register that is asserted
    // when a new key is programmed, and is deasserted
    // when that key has been sent to Key expansion 
    // engine of the core.
    reg new_key;

    // New IV indicator
    // Asserted when a new IV is programmed
    // Deasserted when the new IV has been 
    // used to form plaintext.
    reg new_iv;
    // IV register that is updated after every ciphertext block is received
    reg [127:0] iv_reg; 

    //----------------------------------------------//
    // Address Decode
    wire [31:0] reg_addr;
    // assign reg_addr = ~{12'hFFF, vpmask[11:0], 8'h00} & vpaddr;
    assign reg_addr = {8'h00, addr};
    
    wire [3:0] adec_key;    // Each bit corresponds to one word
    wire [3:0] adec_pt;
    wire [3:0] adec_iv;
    wire [3:0] adec_ct;
    wire adec_ctrl;
    wire adec_status;

    assign adec_key = {reg_addr == KEYW0_ADDR,
                       reg_addr == KEYW1_ADDR,
                       reg_addr == KEYW2_ADDR,
                       reg_addr == KEYW3_ADDR};

    assign adec_pt  = {reg_addr == PTW0_ADDR,
                       reg_addr == PTW1_ADDR,
                       reg_addr == PTW2_ADDR,
                       reg_addr == PTW3_ADDR};

    assign adec_iv  = {reg_addr == IVW0_ADDR,
                       reg_addr == IVW1_ADDR,
                       reg_addr == IVW2_ADDR,
                       reg_addr == IVW3_ADDR};

    assign adec_ct  = {reg_addr == CTW0_ADDR,
                       reg_addr == CTW1_ADDR,
                       reg_addr == CTW2_ADDR,
                       reg_addr == CTW3_ADDR};

    assign adec_ctrl = (reg_addr == CTRL_ADDR);
    assign adec_status = (reg_addr == STATUS_ADDR);
     
    // Register Write Logic
    wire reg_wren;
    // assign reg_wren = vpsel[vpindex] && vpenable && vpwrite;
    assign reg_wren = valid && wen;

    // Control register
    always @(posedge clk) begin
        if (~resetn) begin
            soft_rst_reg <= 1'b0;
            inputs_valid_reg <= 1'b0;
            encdec_reg <= 1'b0;
            aes_mode_reg <= 2'b00;
        end else if (reg_wren && adec_ctrl) begin
            soft_rst_reg <= wdata[CTRL_SOFT_RST_BIT];
            inputs_valid_reg <= wdata[CTRL_INPUTS_VALID_BIT];
            encdec_reg <= wdata[CTRL_ENCDEC_BIT];
            aes_mode_reg <= wdata[CTRL_AESMODE_MSB:CTRL_AESMODE_LSB];
        end else
            inputs_valid_reg <= 1'b0;
    end
    
    // Key, PT, and IV registers.
    // These will be cleared upon soft rst
    always @(posedge clk) begin
        if (~resetn || soft_rst_reg) begin
            key_reg <= 128'd0;
            input_block_reg <= 128'd0;
            iv_reg_initial <= 128'd0;
        end else begin
            // Write key word
            if (reg_wren && adec_key[0])
                key_reg[31:0] <= wdata;
            if (reg_wren && adec_key[1])
                key_reg[63:32] <= wdata;
            if (reg_wren && adec_key[2])
                key_reg[95:64] <= wdata;
            if (reg_wren && adec_key[3])
                key_reg[127:96] <= wdata;
            
            // Write PT word
            if (reg_wren && adec_pt[0])
                input_block_reg[31:0] <= wdata;
            if (reg_wren && adec_pt[1])
                input_block_reg[63:32] <= wdata;
            if (reg_wren && adec_pt[2])
                input_block_reg[95:64] <= wdata;
            if (reg_wren && adec_pt[3])
                input_block_reg[127:96] <= wdata;

            // Write IV word
            if (reg_wren && adec_iv[0])
                iv_reg_initial[31:0] <= wdata;
            if (reg_wren && adec_iv[1])
                iv_reg_initial[63:32] <= wdata;
            if (reg_wren && adec_iv[2])
                iv_reg_initial[95:64] <= wdata;
            if (reg_wren && adec_iv[3])
                iv_reg_initial[127:96] <= wdata;
        end
    end
    
    // Register read logic
    wire reg_rden;
    reg [31:0] readdata;

    assign ready = valid;

    // assign reg_rden = vpsel[vpindex] && vpenable && (~vpwrite);
    assign reg_rden = valid && (~wen);
    assign rdata = readdata;

    always@* begin
        readdata = 32'd0;
        if (reg_rden) begin
            case(1'b1) 
                adec_key[0]: readdata = key_reg[31:0];
                adec_key[1]: readdata = key_reg[63:32];
                adec_key[2]: readdata = key_reg[95:64];
                adec_key[3]: readdata = key_reg[127:96];

                adec_pt[0]: readdata = input_block_reg[31:0];
                adec_pt[1]: readdata = input_block_reg[63:32];
                adec_pt[2]: readdata = input_block_reg[95:64];
                adec_pt[3]: readdata = input_block_reg[127:96];

                adec_iv[0]: readdata = iv_reg_initial[31:0];
                adec_iv[1]: readdata = iv_reg_initial[63:32];
                adec_iv[2]: readdata = iv_reg_initial[95:64];
                adec_iv[3]: readdata = iv_reg_initial[127:96];

                adec_ct[0]: readdata = output_block_reg[31:0];
                adec_ct[1]: readdata = output_block_reg[63:32];
                adec_ct[2]: readdata = output_block_reg[95:64];
                adec_ct[3]: readdata = output_block_reg[127:96];

                adec_ctrl:
                begin
                    readdata[CTRL_SOFT_RST_BIT] = soft_rst_reg;
                    readdata[CTRL_ENCDEC_BIT] = encdec_reg;
                    readdata[CTRL_INPUTS_VALID_BIT] = inputs_valid_reg;
                    readdata[CTRL_AESMODE_MSB:CTRL_AESMODE_LSB] = aes_mode_reg;
                    readdata[31:CTRL_REG_SIZE] = {32-CTRL_REG_SIZE{1'b0}};
                end

                adec_status: readdata = {31'd0, output_ready_reg};
                default: readdata = 32'd0;
            endcase
        end else
            readdata = 32'd0;
    end

    //----------------------------------------------//
    // Instantiate AES Core
    aes_comp_core u_aes_comp_core (
        .clk     (clk),
        .reset_n (core_rstn),
        .encdec  (core_encdec),
        .init    (core_init),
        .next    (core_next),
        .ready   (core_ready),
        .key     (core_key),
        .keylen  (core_keylen),
        .block   (core_block),
        .result  (core_result),
        .result_valid (core_result_valid)
    );
    
    assign core_rstn   = (resetn && ~soft_rst_reg);
    assign core_encdec = encdec_reg;
    assign core_key    = key_reg;
    assign core_keylen = 1'b0;
    assign core_block  = encdec_reg ? 
                         ((aes_mode_reg == AES_MODE_ECB) ? input_block_reg :
                          (aes_mode_reg == AES_MODE_CBC) ? input_block_reg ^ iv_reg :
                                                           input_block_reg) : input_block_reg;

    
    //----------------------------------------------//
    // State Machine
    localparam STATE_IDLE = 2'b00,
               STATE_INIT_KEY = 2'b01,
               STATE_NEW_BLOCK = 2'b10,
               STATE_WAIT_RESULT = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // FSM Combinational Logic
    always @* begin
        core_init = 1'b0;
        core_next = 1'b0;
        next_state = 2'b00;

        case(current_state)
            STATE_IDLE: 
            begin
                if (inputs_valid_reg) begin
                    if (new_key) begin
                        next_state = STATE_INIT_KEY;
                        core_init = 1'b1;
                    end else begin
                        next_state = STATE_NEW_BLOCK;
                        core_next = 1'b1;
                    end
                end else begin
                    next_state = STATE_IDLE;
                    core_init = 1'b0;
                    core_next = 1'b0;
                end
            end

            STATE_INIT_KEY:
            begin
                if (core_ready) begin
                    next_state = STATE_NEW_BLOCK;
                    core_next = 1'b1;
                end else begin
                    next_state = STATE_INIT_KEY;
                    core_init = 1'b0;
                    core_next = 1'b0;
                end
            end

            STATE_NEW_BLOCK:
            begin    
                next_state = STATE_WAIT_RESULT;
                core_next = 1'b0;
            end

            STATE_WAIT_RESULT:
            begin
                if (core_result_valid)
                    next_state = STATE_IDLE;
                else
                    next_state = STATE_WAIT_RESULT;
            end

            default: 
            begin
                next_state = STATE_IDLE;
                core_init = 1'b0;
                core_next = 1'b0;
            end
        endcase
    end
    
    // FSM Sequential logic 
    always @(posedge clk) begin
        if (~resetn)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end


    // New key indicator
    always @(posedge clk) begin
        if (~resetn || soft_rst_reg)
            new_key <= 1'b0;
        else begin
            // Assert when any word of the key is changed
            if (reg_wren && |adec_key)
                new_key <= 1'b1;
            // Deassert once key has been sent to key expansion engine
            else if (current_state == STATE_INIT_KEY)
                new_key <= 1'b0;
        end
    end
   
    // New IV indicator
    always @(posedge clk) begin
        if (~resetn || soft_rst_reg) 
            new_iv <= 1'b0;
        else begin
            if (reg_wren && |adec_iv)
                new_iv <= 1'b1;
            else if (current_state == STATE_NEW_BLOCK)
                new_iv <= 1'b0;
        end
    end
    
    // IV reg update - When new IV is programmed, this 
    // simply takes the value of IV reg. When ciphertext 
    // output is received, this takes the CT value
    always @(posedge clk) begin
        if (~resetn || soft_rst_reg)
            iv_reg <= 128'd0;
        else begin
            if ((next_state == STATE_NEW_BLOCK) && new_iv)
                iv_reg <= iv_reg_initial;
            else if ((current_state == STATE_WAIT_RESULT) && core_result_valid) begin 
                if (encdec_reg) // Encryption
                    iv_reg <= core_result;
                else
                    iv_reg <= input_block_reg;
            end
        end
    end

    // Store outputs and assert output_ready flag
    always @(posedge clk) begin
        if (~resetn || soft_rst_reg) begin
            output_ready_reg <= 1'b0;
            output_block_reg <= 128'd0;
        end else begin
            // Clear if new inputs are programmed
            if (inputs_valid_reg)
                output_ready_reg <= 1'b0;
            // Assert when core has valid result
            else if ((current_state == STATE_WAIT_RESULT) && core_result_valid) begin
                output_ready_reg <= 1'b1;
                
                case (aes_mode_reg)
                    AES_MODE_ECB: output_block_reg <= core_result;
                    AES_MODE_CBC:
                    begin
                        if (encdec_reg) // Encryption
                            output_block_reg <= core_result;
                        else            // Decryption
                            output_block_reg <= core_result ^ iv_reg;
                    end

                    default: output_block_reg <= core_result;
                endcase
            end
        end
    end
endmodule
