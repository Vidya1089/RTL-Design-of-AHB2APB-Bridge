`timescale 1ns/1ps

module bridge_rtl_tb;

reg hclk, hresetn, hselapb, hwrite;
reg [1:0] htrans;
reg [31:0] haddr, hwdata;
reg [31:0] prdata;
wire [31:0] paddr, pwdata;
wire psel, penable, pwrite, hready, hresp;
wire [31:0] hrdata;

// Instantiate DUT
bridge_rtl dut (
    .hclk(hclk),
    .hresetn(hresetn),
    .hselapb(hselapb),
    .hwrite(hwrite),
    .htrans(htrans),
    .haddr(haddr),
    .hwdata(hwdata),
    .prdata(prdata),
    .paddr(paddr),
    .pwdata(pwdata),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .hresp(hresp),
    .hready(hready),
    .hrdata(hrdata)
);

// Clock generation
initial hclk = 0;
always #10 hclk = ~hclk; // 50 MHz

// Dumpfile for waveform
initial begin
    $dumpfile("bridge_rtl_waveform.vcd");
    $dumpvars(0, bridge_rtl_tb);
end

// Main stimulus
initial begin
    // Initialize inputs
    hresetn = 0;
    hselapb = 0;
    hwrite = 0;
    htrans = 2'b00;
    haddr = 0;
    hwdata = 0;
    prdata = 0;

    // Apply reset
    #25;
    hresetn = 1;

    // === AHB SINGLE READ ===
    $display("------ AHB SINGLE READ ------");
    hselapb = 1;
    hwrite = 0;
    htrans = 2'b10;       // NONSEQ
    haddr = 32'h00000004;
    prdata = 32'h0000000A;
    #60;

    // === AHB SINGLE WRITE ===
    $display("------ AHB SINGLE WRITE ------");
    hselapb = 1;
    hwrite = 1;
    htrans = 2'b10;
    haddr = 32'h00000008;
    hwdata = 32'h0000000F;
    #60;

    // === AHB BURST READ (2 Transfers) ===
    $display("------ AHB BURST READ ------");
    hselapb = 1;
    hwrite = 0;
    htrans = 2'b10;
    haddr = 32'h00000010;
    prdata = 32'h00000001; #20;
    htrans = 2'b11;
    haddr = 32'h00000014;
    prdata = 32'h00000002; #20;

    // === AHB BURST WRITE (2 Transfers) ===
    $display("------ AHB BURST WRITE ------");
    hselapb = 1;
    hwrite = 1;
    htrans = 2'b10;
    haddr = 32'h00000020;
    hwdata = 32'h00000005; #20;
    htrans = 2'b11;
    haddr = 32'h00000024;
    hwdata = 32'h00000006; #20;

    // End
    hselapb = 0;
    hwrite = 0;
    htrans = 2'b00;
    $display("------ TEST DONE ------");

    #100;
    $finish;
end

endmodule
