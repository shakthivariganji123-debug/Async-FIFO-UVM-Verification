// Parameterized Dual-Clock Asynchronous FIFO
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,
    input  wire [DATA_WIDTH-1:0] wdata,
    output wire                  wfull,

    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire                  rempty
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   wptr, rptr;
    reg [ADDR_WIDTH:0]   wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0]   wq2_rptr, wq1_rptr;
    reg [ADDR_WIDTH:0]   rq2_wptr, rq1_wptr;

    // Write operation
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read operation
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Binary to Gray conversion
    wire [ADDR_WIDTH:0] wgray_next = (wptr + (winc & !wfull)) ^ ((wptr + (winc & !wfull)) >> 1);
    wire [ADDR_WIDTH:0] rgray_next = (rptr + (rinc & !rempty)) ^ ((rptr + (rinc & !rempty)) >> 1);

    // Pointer logic - Write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr      <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr      <= wptr + 1'b1;
            wptr_gray <= wgray_next;
        end
    end

    // Pointer logic - Read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr      <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr      <= rptr + 1'b1;
            rptr_gray <= rgray_next;
        end
    end

    // 2-stage synchronizer: Read pointer to Write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wq1_rptr <= 0;
            wq2_rptr <= 0;
        end else begin
            wq1_rptr <= rptr_gray;
            wq2_rptr <= wq1_rptr;
        end
    end

    // 2-stage synchronizer: Write pointer to Read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rq1_wptr <= 0;
            rq2_wptr <= 0;
        end else begin
            rq1_wptr <= wptr_gray;
            rq2_wptr <= rq1_wptr;
        end
    end

    // Full & Empty Flag generation
    assign rempty = (rptr_gray == rq2_wptr);
    assign wfull  = (wptr_gray == {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1], wq2_rptr[ADDR_WIDTH-2:0]});

endmodule
