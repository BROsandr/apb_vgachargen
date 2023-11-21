package vgachargen_pkg;

  parameter int unsigned HD = 640; // Display area
  parameter int unsigned HF = 16;  // Front porch
  parameter int unsigned HR = 96;  // Retrace/Sync
  parameter int unsigned HB = 48;  // Back Porch
  parameter int unsigned VD = 480;
  parameter int unsigned VF = 10;
  parameter int unsigned VR = 2;
  parameter int unsigned VB = 33;

  parameter int unsigned HTOTAL = HD + HF + HR + HB;
  parameter int unsigned VTOTAL = VD + VF + VR + VB;

  parameter int unsigned VGA_MAX_H_WIDTH = $clog2(HTOTAL);
  parameter int unsigned VGA_MAX_V_WIDTH = $clog2(VTOTAL);
endpackage
