module timing_generator
  import vgachargen_pkg::*;
(
  input  logic                       clk_i,
  input  logic                       arstn_i,
  input  logic                       en_i,

  output logic                       vga_hs_o,
  output logic                       vga_vs_o,

  // Display timing counters
  output logic [VGA_MAX_H_WIDTH-1:0] hcount_o,
  output logic [VGA_MAX_V_WIDTH-1:0] vcount_o,
  output logic                       pixel_enable_o

);

  logic [VGA_MAX_H_WIDTH-1:0] hcount_ff;
  logic hcount_en;
  logic [VGA_MAX_H_WIDTH-1:0] hcount_next;

  logic [VGA_MAX_V_WIDTH-1:0] vcount_ff;
  logic vcount_en;
  logic [VGA_MAX_V_WIDTH-1:0] vcount_next;

  // Horizontal counter
  assign hcount_next = ( hcount_ff < ( HTOTAL - 1 ) ) ? ( hcount_ff + 1 ) : ( '0 );
  always_ff @ ( posedge clk_i or negedge arstn_i )
    if      ( ~arstn_i  ) hcount_ff <= '0;
    else if (en_i)        hcount_ff <= hcount_next;

  // Vertical counter
  assign vcount_en   = ( hcount_ff == ( HTOTAL - 1 ) ) & en_i;
  assign vcount_next = ( vcount_ff < ( VTOTAL - 1 ) ) ? ( vcount_ff + 1 ) : ( '0 );
  always_ff @( posedge clk_i or negedge arstn_i )
    if      ( ~arstn_i    ) vcount_ff <= '0;
    else if ( vcount_en   ) vcount_ff <= vcount_next;

  enum {
    DISPLAY_S,
    FRONT_S,
    SYNC_S,
    BACK_S
  } hstate_ff, hstate_next,
    vstate_ff, vstate_next;

  always_ff @( posedge clk_i or negedge arstn_i )
    if( ~arstn_i ) begin
      hstate_ff <= DISPLAY_S;
      vstate_ff <= DISPLAY_S;
    end else if (en_i) begin
      hstate_ff <= hstate_next;
      vstate_ff <= vstate_next;
    end

  always_comb begin
    hstate_next = hstate_ff;
    unique case( hstate_ff)
      DISPLAY_S: if( hcount_ff == HD - 1 )           hstate_next = FRONT_S;

      FRONT_S:   if( hcount_ff == HD + HF - 1 )      hstate_next = SYNC_S;

      SYNC_S:    if( hcount_ff == HD + HF + HR - 1 ) hstate_next = BACK_S;

      BACK_S:    if( hcount_ff == HTOTAL - 1 )       hstate_next = DISPLAY_S;

      default:                                       hstate_next = DISPLAY_S;
    endcase
  end

  always_comb begin
    vstate_next = vstate_ff;
    if( vcount_en ) begin
      unique case( vstate_ff)
        DISPLAY_S: if( vcount_ff == VD - 1 )           vstate_next = FRONT_S;

        FRONT_S:   if( vcount_ff == VD + VF - 1 )      vstate_next = SYNC_S;

        SYNC_S:    if( vcount_ff == VD + VF + VR - 1 ) vstate_next = BACK_S;

        BACK_S:    if( vcount_ff == VTOTAL - 1 )       vstate_next = DISPLAY_S;

        default:                                       vstate_next = DISPLAY_S;
      endcase
    end
  end

  assign vga_hs_o = hstate_ff inside {DISPLAY_S, FRONT_S, BACK_S};
  assign vga_vs_o = vstate_ff inside {DISPLAY_S, FRONT_S, BACK_S};

  assign pixel_enable_o = ( vstate_ff == DISPLAY_S ) && ( hstate_ff == DISPLAY_S );

  assign hcount_o = hcount_ff;
  assign vcount_o = vcount_ff;
endmodule
