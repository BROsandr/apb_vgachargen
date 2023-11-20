module timing_generator
  import vgachargen_pkg::*;
(
  input  logic                       clk_i, 
  input  logic                       arstn_i,
  
  output logic                       vga_hs_o, 
  output logic                       vga_vs_o,

  input  logic [VGA_MAX_H_WIDTH-1:0] hd_i, // Display area
  input  logic [VGA_MAX_H_WIDTH-1:0] hf_i, // Front porch
  input  logic [VGA_MAX_H_WIDTH-1:0] hr_i, // Retrace/Sync
  input  logic [VGA_MAX_H_WIDTH-1:0] hb_i, // Back Porch    
  
  input  logic [VGA_MAX_V_WIDTH-1:0] vd_i,
  input  logic [VGA_MAX_V_WIDTH-1:0] vf_i,
  input  logic [VGA_MAX_V_WIDTH-1:0] vr_i,
  input  logic [VGA_MAX_V_WIDTH-1:0] vb_i,
  
  input  logic                       we_i,

  // Display timing counters
  output logic [VGA_MAX_H_WIDTH-1:0] hcount_o,
  output logic [VGA_MAX_V_WIDTH-1:0] vcount_o,
  output logic                       pixel_enable_o

);
  logic  [VGA_MAX_H_WIDTH-1:0] htotal_ff;
  logic  [VGA_MAX_H_WIDTH-1:0] htotal_next;

  logic  [VGA_MAX_V_WIDTH-1:0] vtotal_ff;
  logic  [VGA_MAX_V_WIDTH-1:0] vtotal_next;

  assign htotal_next = hd_i + hf_i + hr_i + hb_i;
  assign vtotal_next = vd_i + vf_i + vr_i + vb_i;
  
  // Sync signal registers, vertical counter enable register, and pixel enable register
  logic hsync_ff;
  logic hsync_en;
  logic hsync_next;

  logic vsync_ff;
  logic vsync_en;
  logic vsync_next;

  logic [VGA_MAX_H_WIDTH-1:0] hcount_ff;
  logic hcount_en;
  logic [VGA_MAX_H_WIDTH-1:0] hcount_next;

  logic [VGA_MAX_V_WIDTH-1:0] vcount_ff;
  logic vcount_en;
  logic [VGA_MAX_V_WIDTH-1:0] vcount_next;

  logic pixel_enable_ff;
  logic pixel_enable_en;
  logic pixel_enable_next;

  logic [VGA_MAX_H_WIDTH-1:0] hd_ff; // Display area
  logic [VGA_MAX_H_WIDTH-1:0] hf_ff; // Front porch
  logic [VGA_MAX_H_WIDTH-1:0] hr_ff; // Retrace/Sync
  logic [VGA_MAX_H_WIDTH-1:0] hb_ff; // Back Porch    
  
  logic [VGA_MAX_V_WIDTH-1:0] vd_ff;
  logic [VGA_MAX_V_WIDTH-1:0] vf_ff;
  logic [VGA_MAX_V_WIDTH-1:0] vr_ff;
  logic [VGA_MAX_V_WIDTH-1:0] vb_ff;

  always_ff @ ( posedge clk_i or negedge arstn_i )
    if          ( ~arstn_i ) begin
      hd_ff <= '1;
      hf_ff <= '0;
      hr_ff <= '0;
      hb_ff <= '0;

      vd_ff <= '1;
      vf_ff <= '0;
      vr_ff <= '0;
      vb_ff <= '0;

      htotal_ff <= '0;
      vtotal_ff <= '0;
    end else if ( we_i     ) begin
      hd_ff <= hd_i;
      hf_ff <= hf_i;
      hr_ff <= hr_i;
      hb_ff <= hb_i;

      vd_ff <= vd_i;
      vf_ff <= vf_i;
      vr_ff <= vr_i;
      vb_ff <= vb_i;

      htotal_ff <= htotal_next;
      vtotal_ff <= vtotal_next;
    end
  
  // Horizontal counter
  assign hcount_next = ( hcount_ff < ( htotal_ff - 1 ) ) ? ( hcount_ff + 1 ) : ( '0 );
  always_ff @ ( posedge clk_i or negedge arstn_i )
    if      ( ~arstn_i  ) hcount_ff <= '0;
    else                  hcount_ff <= hcount_next;
  
  // Vertical counter
  assign vcount_en   = ( hcount_ff == ( htotal_ff - 1 ) );
  assign vcount_next = ( vcount_ff < ( vtotal_ff - 1 ) ) ? ( vcount_ff + 1 ) : ( '0 );
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
    end else begin
      hstate_ff <= hstate_next;
      vstate_ff <= vstate_next;
    end

  always_comb begin
    hstate_next = hstate_ff;
    unique case( hstate_ff)
      DISPLAY_S: if( hcount_ff == hd_ff - 1 )                 hstate_next = FRONT_S;

      FRONT_S:   if( hcount_ff == hd_ff + hf_ff - 1 )         hstate_next = SYNC_S;

      SYNC_S:    if( hcount_ff == hd_ff + hf_ff + hr_ff - 1 ) hstate_next = BACK_S;

      BACK_S:    if( hcount_ff == htotal_ff - 1 )             hstate_next = DISPLAY_S;

      default:                                                hstate_next = DISPLAY_S;
    endcase
  end

  always_comb begin
    vstate_next = vstate_ff;
    if( vcount_en ) begin
      unique case( vstate_ff)
        DISPLAY_S: if( vcount_ff == vd_ff - 1 )                 vstate_next = FRONT_S;

        FRONT_S:   if( vcount_ff == vd_ff + vf_ff - 1 )         vstate_next = SYNC_S;

        SYNC_S:    if( vcount_ff == vd_ff + vf_ff + vr_ff - 1 ) vstate_next = BACK_S;

        BACK_S:    if( vcount_ff == vtotal_ff - 1 )             vstate_next = DISPLAY_S;

        default:                                                vstate_next = DISPLAY_S;
      endcase
    end
  end

  assign vga_hs_o = hstate_ff inside {DISPLAY_S, FRONT_S, BACK_S};
  assign vga_vs_o = vstate_ff inside {DISPLAY_S, FRONT_S, BACK_S};

  assign pixel_enable_o = ( vstate_ff == DISPLAY_S ) && ( hstate_ff == DISPLAY_S ); 
  
  assign hcount_o = hcount_ff;
  assign vcount_o = vcount_ff;

// X Checks
  sva_x_check_we_i: assert property(
    @(posedge clk_i)
    !$isunknown(we_i)
  ) else begin
    $fatal("sva:we_i is unknown");
  end  

  sva_x_check_timings: assert property(
    @(posedge clk_i)
    we_i |-> !$isunknown({
        hd_i,
        hf_i,
        hr_i,
        hb_i,
        vd_i,
        vf_i,
        vr_i,
        vb_i
    })
  ) else begin
    $fatal("sva:timings is unknown while we_i");
  end  

  sva_x_check_count: assert property(
    @(posedge clk_i)
    !$isunknown({hcount_o, vcount_o})
  ) else begin
    $fatal("sva:count is unknown");
  end

  sva_x_check_pixel_enable: assert property(
    @(posedge clk_i)
    !$isunknown(pixel_enable_o)
  ) else begin
    $fatal("sva:pixel_enable is unknown");
  end

// Behavioral
  sva_x_check_hd_is_greater: assert property(
    @(posedge clk_i)
    hd_i > hf_i && hd_i > hr_i && hd_i > hb_i
  ) else begin
    $fatal("sva:hd_i is lesser or equal than hf_i || hr_i || hb_i");
  end
  
  sva_x_check_vd_is_greater: assert property(
    @(posedge clk_i)
    vd_i > vf_i && vd_i > vr_i && vd_i > vb_i
  ) else begin
    $fatal("sva:vd_i is lesser or equal than vf_i || vr_i || vb_i");
  end

  localparam                     VGA_MAX_WIDTH_FLAT = VGA_MAX_H_WIDTH*VGA_MAX_V_WIDTH;
  logic [VGA_MAX_WIDTH_FLAT-1:0] pixel_counter_ff;
  logic                          pixel_counter_en;
  assign                         pixel_counter_en   = (!vga_vs_o || pixel_enable_o);
  logic [VGA_MAX_WIDTH_FLAT-1:0] pixel_counter_next;
  assign                         pixel_counter_next = (!vga_vs_o) ?
                                                      ('0)        :
                                                      (pixel_counter_ff + VGA_MAX_WIDTH_FLAT'(1));
  always_ff @(posedge clk_i or negedge arstn_i) begin
    if      (!arstn_i)         pixel_counter_ff <= '0;
    else if (pixel_counter_en) pixel_counter_ff <= pixel_counter_next;
  end
  sva_pixel_enable_eq_hd_vd: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    $fell(vga_vs_o) |-> pixel_counter_ff == hd_ff * vd_ff
  ) else begin
    $fatal("sva:pixel_enable==1 total time != HD * VD");
  end

  sva_vcount_change_on_hcount_reset: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    !$stable(vcount_o) |-> ~|hcount_ff && ($past(hcount_o) == (htotal_ff - VGA_MAX_H_WIDTH'(1)))
  ) else begin
    $fatal("sva:vcount changed but hcount was not reseted");
  end

  sva_vcount_fell_on_timing: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    $fell(vga_vs_o) |-> vcount_o == (vd_ff + vf_ff)
  ) else begin
    $fatal("sva:vs pulse not on display_time + front_porch_time");
  end

  sva_vcount_rose_on_timing: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    $rose(vga_vs_o) |-> vcount_o == (vtotal_ff - vb_ff)
  ) else begin
    $fatal("sva:vs pulse not on display_time + front_porch_time + sync_pulse");
  end

  sva_hcount_fell_on_timing: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    $fell(vga_hs_o) |-> hcount_o == (hd_ff + hf_ff)
  ) else begin
    $fatal("sva:hs pulse not on display_time + front_porch_time");
  end

  sva_hcount_rose_on_timing: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    $rose(vga_hs_o) |-> hcount_o == (htotal_ff - hb_ff)
  ) else begin
    $fatal("sva:hs pulse not on display_time + front_porch_time + sync_pulse");
  end

  sva_enable_inside_display: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    pixel_enable_o |-> (vcount_o inside {[0:vd_ff]}) && (hcount_o inside {[0:hd_ff]})
  ) else begin
    $fatal("sva:pixel_enable_o==1 outside the display area");
  end

  sva_enable_outside_pulse: assert property(
    @(posedge clk_i) disable iff (!arstn_i)
    pixel_enable_o |-> vga_hs_o && vga_vs_o
  ) else begin
    $fatal("sva:pixel_enable_o==1 inside the pulse");
  end
endmodule
