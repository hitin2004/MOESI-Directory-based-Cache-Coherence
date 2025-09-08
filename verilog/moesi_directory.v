`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.07.2025 14:21:46
// Design Name: 
// Module Name: moesi_directory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////





`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.07.2025 14:21:46
// Design Name: 
// Module Name: moesi_directory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module distributed_moesi(
    input clk,
    input reset,
    input [1:0] req_proc,          // ID of processor
    input read_req,                // Read request signal
    input write_req,               // Write request signal
    output [2:0] state_p0,         // Output: Cache state of p0
    output [2:0] state_p1,         // Output: Cache state of p1
    output [2:0] state_p2          // Output: Cache state of p2
);

    // MOESI states
    parameter I = 3'b000, S = 3'b001, E = 3'b010, O = 3'b011, M = 3'b100;

    // Local cache states for each processor
    reg [2:0] state0, state1, state2;
    assign state_p0 = state0;
    assign state_p1 = state1;
    assign state_p2 = state2;

    // Each processor has its own directory info to manage its local memory block
    reg [2:0] dir_state0, dir_state1, dir_state2;
    reg [2:0] share0, share1, share2;
    reg [1:0] owner0, owner1, owner2;

    // Helper task to set the cache state of a specific processor
    task set_state;
        input [1:0] proc;
        input [2:0] val; // state assigning like m e o s i n stuff
        begin
            case (proc)
                2'd0: state0 <= val;
                2'd1: state1 <= val;
                2'd2: state2 <= val;
            endcase
        end
    endtask

    // to invalidate all other processor caches except the one requesting
    task invalidate_others;
        input [1:0] keeper; // not to invalidate the proc of keeper, invlaidate others basivally
        begin
            if (keeper != 2'd0) state0 <= I;
            if (keeper != 2'd1) state1 <= I;
            if (keeper != 2'd2) state2 <= I;
        end
    endtask

    // Directory control logic for each processor's local memory block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state0 <= I; state1 <= I; state2 <= I;
            dir_state0 <= I; dir_state1 <= I; dir_state2 <= I;
            share0 <= 3'b000; share1 <= 3'b000; share2 <= 3'b000;
            owner0 <= 2'd0; owner1 <= 2'd0; owner2 <= 2'd0;
        end else begin
            case (req_proc)
                2'd0: handle_dir(req_proc, read_req, write_req, dir_state0, share0, owner0);
                2'd1: handle_dir(req_proc, read_req, write_req, dir_state1, share1, owner1);
                2'd2: handle_dir(req_proc, read_req, write_req, dir_state2, share2, owner2);
            endcase
        end
    end

    // Enhanced directory controller task to handle all read/write hits and misses
    task handle_dir;
        input [1:0] proc;
        input read, write;
        inout [2:0] dir_state;
        inout [2:0] sharing;
        inout [1:0] owner;
        reg [2:0] cur_state;
        begin
            case (proc)
                2'd0: cur_state = state0;
                2'd1: cur_state = state1;
                2'd2: cur_state = state2;
            endcase

            if (read) begin
                if (cur_state == M || cur_state == E || cur_state == S || cur_state == O) begin
                    // Read hit — no state change needed
                end else if (dir_state == I) begin
                    // Uncached read — exclusive access
                    dir_state <= E;
                    sharing <= 1 << proc; // when this is the first to be shared
                    owner <= proc;
                    set_state(proc, E);
                end else if (dir_state == E || dir_state == S) begin
                    // Shared read — upgrade to S and add sharer
                    dir_state <= S;
                    sharing[proc] <= 1;  // adding sharers ( more than one) 
                    set_state(proc, S);
                end else if (dir_state == M || dir_state == O) begin
                    // Dirty read — convert owner to O, requester to S
                    dir_state <= O;
                    sharing[proc] <= 1;
                    sharing[owner] <= 1;
                    set_state(proc, S);
                    set_state(owner, O);
                end
            end else if (write) begin
                if (cur_state == M) begin
                    // Write hit — already has ownership
                end else if (cur_state == E) begin
                    // Silent upgrade from E to M
                    dir_state <= M;
                    sharing <= 1 << proc; // when its the only one sharing ( first sharer) 
                    owner <= proc;
                    set_state(proc, M);
                end else if (cur_state == S || cur_state == O) begin
                    // Shared write — invalidate others and gain ownership
                    dir_state <= M;
                    sharing <= 1 << proc;
                    owner <= proc;
                    set_state(proc, M);
                    invalidate_others(proc);
                end else begin
                    // Write miss — gain ownership and invalidate others
                    dir_state <= M;
                    sharing <= 1 << proc;
                    owner <= proc;
                    set_state(proc, M);
                    invalidate_others(proc);
                end
            end
        end
    endtask

endmodule
