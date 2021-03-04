module Top (
    input        i_clk,
    input        i_rst_n, // key[1]
    input        i_start, // key[0]
    input        i_hist,  // key[2]
    input        i_pause, // key[3]
    output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first
// ===== States =====
parameter S_IDLE = 2'b000;
parameter S_WAIT = 3'b001;
parameter S_DISP = 3'b010;
parameter S_HIST = 3'b011;
parameter S_SUSP = 3'b100;
parameter TIME_LIMIT = {1'b1, 27'b0};


// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;

// ===== Registers & Wires =====
logic [3:0]new_random;
logic state_r, state_w; // last, current
logic counter = 32'b0;

// ===== import modules =====
rnGen rng(.i_rst_n(i_rst_n),
        .i_clk(i_clk),
        .o_random(new_random));

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    o_random_out_w = o_random_out_r;
    state_w        = state_r;

    // press key[0] to get to S_IDLE state
    if (i_rst_n) begin
        state_w = S_IDLE;
        o_random_out_w = 4'b0;
    end
    
    // FSM
    case(state_r)
    S_IDLE: begin
        // press key[0] to start generating and the delay counter
        if (i_start) state_w = S_WAIT;
        if (i_hist) state_w = S_HIST;
    end

    S_WAIT: begin
        // press key[3] to get in S_SUSP state
        if (i_wait) state_w = S_SUSP;
        // final generated value
        if (counter >= TIME_LIMIT) begin
            state_w = S_DISP;
        end
    end

    S_DISP: begin
        // TODO: display, set o_random_out_w to be the current random value
        // TODO: to go back wait
    end

    S_HIST: begin
        // press key[0] to start generating and the delay counter
        if (i_start) state_w = S_WAIT;
        // TODO: set o_random_out_w to be the previous one

    end

    S_SUSP: begin
        // press key[0] to start generating and the delay counter
        if (i_start) state_w = S_WAIT;
    end

    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    // reset
    if (!i_rst_n) begin
        o_random_out_r <= 4'd0;
        state_r        <= S_IDLE;
        counter 	   <= 32'b0;
    end
    else begin
        o_random_out_r <= o_random_out_w;
        state_r        <= state_w;
        counter        <= counter + 1'b1;
    end
end

endmodule

module rnGen (
    input i_rst_n,
    input i_clk,
    output [3:0] o_random
);

    logic [3:0]r_val, [3:0]w_val;
    logic feedback;

    assign o_random = r_val;
    assign feedback = r_val[3] ^ r_val[2] ^ r_val[0];
    assign w_val = {feedback, r_val[3:1]};

    always_ff @( posedge i_clk or negedge i_rst_n ) begin
        if (!i_rst_n) begin
            r_val = 1'b1;
        end
        else begin
            r_val <= w_val;
        end
    end
    
endmodule