module bridge_rtl(
    input hclk, hresetn, hselapb, hwrite,
    input [1:0] htrans,
    input [31:0] haddr,
    input [31:0] hwdata,
    input [31:0] prdata,
    output reg [31:0] paddr, pwdata,
    output reg psel, penable, pwrite,
    output reg hresp, hready,
    output reg [31:0] hrdata
);

parameter idle       = 3'b000;
parameter read       = 3'b001;
parameter wwait      = 3'b010;
parameter write      = 3'b011;
parameter write_p    = 3'b100;
parameter wenable_p  = 3'b101;  
parameter wenable    = 3'b110;
parameter renable    = 3'b111;

reg [31:0] haddr_temp, hwdata_temp;
reg [2:0] present_state, next_state;
reg valid;
reg hwrite_temp;

// State register
always @(posedge hclk or negedge hresetn) begin
    if (!hresetn)
        present_state <= idle;
    else
        present_state <= next_state;
end

// Combinational logic
always @(*) begin
    // Fix: assign hresp to 0 to avoid 'x' in waveform
    hresp = 0;

    if (hselapb && (htrans == 2'b10 || htrans == 2'b11))
        valid = 1;
    else
        valid = 0;

    case (present_state)
        idle: begin
            psel    = 0; penable = 0; hready = 1;
            if (!valid)
                next_state = idle;
            else if (valid && !hwrite)
                next_state = read;
            else
                next_state = wwait;
        end

        read: begin
            psel = 1; paddr = haddr; pwrite = 0; penable = 0; hready = 0;
            next_state = renable;
        end

        renable: begin
            penable = 1; hrdata = prdata; hready = 1;
            if (valid && !hwrite)
                next_state = read;
            else if (valid && hwrite)
                next_state = wwait;
            else
                next_state = idle;
        end

        wwait: begin
            penable = 0; haddr_temp = haddr; hwrite_temp = hwrite; hwdata_temp = hwdata;
            if (!valid)
                next_state = write;
            else
                next_state = write_p;
        end

        write: begin
            psel = 1; paddr = haddr_temp; pwdata = hwdata_temp;
            pwrite = 1; penable = 0; hready = 0;
            if (!valid)
                next_state = wenable;
            else
                next_state = wenable_p;
        end

        write_p: begin
            psel = 1; paddr = haddr_temp; pwdata = hwdata_temp;
            pwrite = 1; penable = 0; hready = 0;
            hwrite_temp = hwrite;
            next_state = wenable_p;
        end

        wenable: begin
            penable = 1; hready = 1;
            if (valid && !hwrite)
                next_state = read;
            else
                next_state = idle;
        end

        wenable_p: begin
            penable = 1; hready = 1;
            if (!valid && hwrite)
                next_state = write;
            else if (valid && hwrite)
                next_state = write_p;
            else
                next_state = read;
        end
    endcase
end

endmodule
