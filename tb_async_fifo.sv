// SystemVerilog & UVM-Style Verification Testbench for Async FIFO
`timescale 1ns/1ps

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    logic                  wclk;
    logic                  wrst_n;
    logic                  winc;
    logic [DATA_WIDTH-1:0] wdata;
    wire                   wfull;

    logic                  rclk;
    logic                  rrst_n;
    logic                  rinc;
    wire  [DATA_WIDTH-1:0] rdata;
    wire                   rempty;

    // Instantiate DUT (Device Under Test)
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty)
    );

    // Clock generation - Asynchronous clocks (Fast Write, Slow Read)
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk; // 100 MHz
    end

    initial begin
        rclk = 0;
        forever #10 rclk = ~rclk; // 50 MHz
    end

    // Testbench Stimulus & Scoreboard Verification
    initial begin
        // Initialize inputs
        wrst_n = 0;
        rrst_n = 0;
        winc   = 0;
        rinc   = 0;
        wdata  = 0;

        // Apply Reset
        #30;
        wrst_n = 1;
        rrst_n = 1;
        #20;

        $display("--------------------------------------------------");
        $display("[TB] Starting Asynchronous FIFO Write Operations");
        $display("--------------------------------------------------");

        // Burst write until FIFO is FULL
        repeat (16) begin
            @(posedge wclk);
            if (!wfull) begin
                winc  <= 1;
                wdata <= $urandom_range(8'h01, 8'hFE);
            end
        end

        @(posedge wclk);
        winc <= 0;
        #40;

        $display("--------------------------------------------------");
        $display("[TB] Starting Asynchronous FIFO Read Operations");
        $display("--------------------------------------------------");

        // Read until FIFO is EMPTY
        repeat (16) begin
            @(posedge rclk);
            if (!rempty) begin
                rinc <= 1;
            end
        end

        @(posedge rclk);
        rinc <= 0;
        #50;

        $display("--------------------------------------------------");
        $display("[TB] Simulation Completed Successfully!");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
