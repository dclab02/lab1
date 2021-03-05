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
parameter S_IDLE = 3'b000;
parameter S_WAIT = 3'b001;
parameter S_DISP = 3'b010;
parameter S_HIST = 3'b011;
parameter S_SUSP = 3'b100;
parameter S_DONE = 3'b101;

parameter TIME_UPPERBOUND = {5'b0, 1'b1, 26'b0};

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;

// ===== Registers & Wires =====
logic [3:0] new_random = 4'b0;
logic [3:0] old_random_w = 4'b0;
logic [3:0] old_random_r = 4'b0;
logic [3:0] state_r, state_w;
logic [31:0] counter = 32'b0;
logic [3:0] cycle_time = 4'b0;
logic [3:0] seed;
logic [31:0] time_limit_r;
logic [3:0] sprinkle_counter = 4'b0;
logic [3:0] random_res;

// ===== import modules =====
rnGen rng(.i_rst_n(i_start),
        .i_clk(i_clk),
        .i_seed(seed),
        .o_random(new_random));

// ===== Output Assignments =====
assign o_random_out = random_res;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values
    o_random_out_w = o_random_out_r;
    state_w        = state_r;
    seed           = cycle_time;
    old_random_w   = old_random_r;
    random_res     = o_random_out_r;
    // FSM
    case(state_r)
    S_IDLE: begin
        // press key[0] to start generating and the delay counter
        if (i_start) state_w = S_WAIT;
        if (i_hist) state_w  = S_HIST;
    end

    S_WAIT: begin
        // press key[3] to get in S_SUSP state
        if (i_pause) state_w = S_SUSP;
        // final generated value
        if (counter >= time_limit_r) begin
            state_w = S_DISP;
        end
    end

    S_DISP: begin
        // display, set o_random_out_w to be the current random value
        // go back wait  
        if (time_limit_r < TIME_UPPERBOUND) begin
            o_random_out_w = new_random;
            state_w        = S_WAIT; 
        end
        if(i_hist) state_w  = S_HIST;
        if(i_start) state_w = S_DONE;
    end

    S_HIST: begin
        // back to done
        if (i_hist) state_w = S_DONE;
        // set output to be the previous one
        random_res= old_random_r;
    end

    S_SUSP: begin
        // press key[0] to start generating
        if (i_start) state_w = S_WAIT;
    end

    S_DONE: begin
        // press key[0] to start generating and the delay counter
        random_res = 4'd0;
        if (i_start) state_w = S_WAIT;
        if (i_hist) state_w  = S_HIST;
    end

    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
    // reset
    if (!i_rst_n) begin
        old_random_r   <= 4'd0;
        o_random_out_r <= 4'd0;
        state_r        <= S_IDLE;
        counter 	   <= 32'b0;
        time_limit_r   <= {10'b0, 1'b1, 21'b0};
    end
    else begin
        o_random_out_r <= o_random_out_w;      
        state_r        <= state_w;
        // if in done mode, record old value
        if(state_w == S_DONE) begin
            old_random_r   <= o_random_out_r;
            counter 	   <= 32'b0;
            time_limit_r   <= {10'b0, 1'b1, 21'b0};
        end
        // if in wait mode, add counter
        if(state_w == S_WAIT) begin
            counter <= counter + 1'b1;
        end
        //  if in display mode sprinkle counter + 1
        if(state_w == S_DISP) begin
            counter   	     <= 32'b0;
            sprinkle_counter <= sprinkle_counter + 1'b1;
        end
        
        // if time to display, shift the time limit
        if((counter >= time_limit_r) && (time_limit_r < TIME_UPPERBOUND) && !(sprinkle_counter & 2'b11)) begin		
            time_limit_r <= time_limit_r << 1'b1;			
        end
    end
    
end

// cycle time
always_ff @(posedge i_clk) begin
    cycle_time <= cycle_time + 1'b1;
end

endmodule

// Random number generator
module rnGen (
    input i_rst_n,
    input i_clk,
    input [3:0] i_seed,
    output [3:0] o_random
);

    logic [3:0] r_val, w_val;
    logic feedback;

    assign o_random = r_val;
    assign feedback = r_val[3] ^ r_val[2] ^ r_val[0];
    assign w_val = {feedback, r_val[3:1]};

    always_ff @( posedge i_clk) begin
        if (i_rst_n) begin
            r_val = i_seed;
        end
        else begin
            r_val <= w_val;
        end
    end
    
endmodule