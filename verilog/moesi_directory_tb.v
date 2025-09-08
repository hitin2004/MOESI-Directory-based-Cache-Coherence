`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.07.2025 14:22:42
// Design Name: 
// Module Name: moesi_directory_tb
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

module distributed_moesi_tb;

    // Inputs
    reg clk = 0;
    reg reset;
    reg [1:0] req_proc;
    reg read_req;
    reg write_req;

    // Outputs
    wire [2:0] state_p0, state_p1, state_p2;

    // Instantiate the DUT
    distributed_moesi dut (
        .clk(clk),
        .reset(reset),
        .req_proc(req_proc),
        .read_req(read_req),
        .write_req(write_req),
        .state_p0(state_p0),
        .state_p1(state_p1),
        .state_p2(state_p2)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to issue a request
    task access;
        input [1:0] proc;
        input integer is_read;
        begin
            req_proc = proc;
            read_req = is_read;
            write_req = ~is_read;
            #10;
            read_req = 0;
            write_req = 0;
            #10;
        end
    endtask

    // Monitoring state
    initial begin
        $display("Time | P0 | P1 | P2 | Action");
        $monitor("%4t | %b | %b | %b", $time, state_p0, state_p1, state_p2);
    end

    initial begin
        // Start
        reset = 1; #12;
        reset = 0; #10;

        // Step 1: P0 reads (read miss) ? E
        access(2'd0, 1); // P0 gets E

        // Step 2: P0 writes (write hit on E) ? should become M, no invalidation needed
        access(2'd0, 0); // P0 gets M

        // Step 3: P0 writes again (write hit on M) ? should do nothing
        access(2'd0, 0); // Still M

        // Step 4: P1 reads ? P0 M ? O, P1 ? S
        access(2'd1, 1);

        // Step 5: P1 writes (write hit on S) ? invalidate P0 (O), become M
        access(2'd1, 0);

        // Step 6: P2 reads ? P1 M ? O, P2 ? S
        access(2'd2, 1);

        // Step 7: P2 writes (write hit on S) ? invalidate P1 (O), become M
        access(2'd2, 0);

        // Step 8: P2 writes again (write hit on M) ? no change
        access(2'd2, 0);

        #20 $finish;
    end

endmodule


