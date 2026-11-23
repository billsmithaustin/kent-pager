// Kent Pager enclosure: a one-piece "sled" behind an M5Stack Cardputer ADV.
//
// Layout, bottom to top:
//   floor
//   lower bay: modem LiPo + 5 V boost/charger board (between the HAT's standoff rows)
//   Waveshare SIM7670G HAT on four standoffs
//   ledge the Cardputer rests on
//   pocket: Cardputer, front (keyboard + screen) facing up and fully exposed
//
// Print floor-down. Units: mm.
//
// Every value marked MEASURE is an estimate. Measure your actual parts and
// adjust before printing. Print a test first: the cutout positions for the
// Cardputer's USB-C port and power switch, and the HAT's SIM slot, are guesses.

/* ---------- print / fit ---------- */
wall      = 2.0;   // outer wall thickness
floor_t   = 2.0;   // floor thickness
clear     = 0.4;   // clearance per side around parts
ledge_t   = 2.0;   // thickness of the ledge under the Cardputer
ledge_w   = 2.5;   // how far the ledge sticks in under the Cardputer
proud     = 1.0;   // how far the Cardputer's front sits above the walls
$fn = 48;

/* ---------- parts ---------- */
cp        = [84.0, 54.0, 19.6];   // Cardputer ADV, from M5Stack docs
hat       = [85.0, 56.7];         // Waveshare SIM7670G HAT footprint, from Waveshare
hat_pcb   = 1.6;
hat_above = 16.0;   // MEASURE: tallest part above the HAT PCB (USB-A ports, antenna connectors)
lower_h   = 10.0;   // MEASURE: tallest part below the HAT (battery ~7, PowerBoost 1000C ~9)

// HAT mounting holes, relative to the HAT's corner. Raspberry Pi HAT pattern
// (58 x 49 mm, 3.5 mm in from the edge). MEASURE on the Waveshare board.
hat_holes = [[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]];
standoff_d    = 5.5;
standoff_hole = 2.2;   // M2.5 self-tapping screw; use 3.2 for heat-set inserts

/* ---------- derived ---------- */
bay       = [max(hat[0], cp[0]) + 2*clear, max(hat[1], cp[1]) + 2*clear];
bay_h     = lower_h + 1 + hat_pcb + hat_above + 1;
pocket    = [cp[0] + 2*clear, cp[1] + 2*clear];
pocket_d  = cp[2] - proud;
outer     = [bay[0] + 2*wall, bay[1] + 2*wall, floor_t + bay_h + ledge_t + pocket_d];
z_ledge   = floor_t + bay_h;           // underside of ledge
z_pocket  = z_ledge + ledge_t;         // Cardputer back rests here
standoff_h = lower_h + 1;

/* ---------- cutouts ----------
   Each cutout: [wall, offset along wall from its left end, z of center, width, height]
   wall: "x0" = left end, "x1" = right end, "y0" = front long side, "y1" = back long side.
*/
cutouts = [
  // USB-C charging socket (panel-mount or breakout) for the modem battery charger, lower bay
  ["x0", outer[1]/2, floor_t + 5, 10.0, 4.5],
  // Cardputer's own USB-C port (charging + firmware). MEASURE position.
  ["x1", outer[1]/2, z_pocket + cp[2]/2, 13.0, 7.0],
  // Cardputer power switch. MEASURE position.
  ["x1", outer[1]/2 + 16, z_pocket + cp[2]/2, 9.0, 5.0],
  // SIM card access slot at HAT level. MEASURE position on the HAT.
  ["y0", 20, floor_t + standoff_h + hat_pcb + 1.5, 18.0, 4.0],
];

// Finger notches on the long walls so the Cardputer can be lifted out.
notch_r = 9;

/* ---------- model ---------- */
module rrect(size, h, r = 2) {
  linear_extrude(h)
    offset(r) offset(-r) square(size);
}

module cutout(c) {
  w = c[0]; off = c[1]; z = c[2]; cw = c[3]; ch = c[4];
  d = wall * 4;
  if (w == "x0") translate([-wall, off - cw/2, z - ch/2]) cube([d, cw, ch]);
  if (w == "x1") translate([outer[0] - 3*wall, off - cw/2, z - ch/2]) cube([d, cw, ch]);
  if (w == "y0") translate([off - cw/2, -wall, z - ch/2]) cube([cw, d, ch]);
  if (w == "y1") translate([off - cw/2, outer[1] - 3*wall, z - ch/2]) cube([cw, d, ch]);
}

module shell() {
  difference() {
    rrect([outer[0], outer[1]], outer[2], 3);

    // lower bay + HAT space
    translate([wall, wall, floor_t]) cube([bay[0], bay[1], bay_h + 0.01]);

    // 45-degree chamfer under the ledge so it prints without supports
    hull() {
      translate([wall, wall, z_ledge - 3]) cube([bay[0], bay[1], 0.01]);
      translate([(outer[0] - pocket[0])/2 + ledge_w, (outer[1] - pocket[1])/2 + ledge_w, z_ledge])
        cube([pocket[0] - 2*ledge_w, pocket[1] - 2*ledge_w, 0.01]);
    }

    // opening through the ledge (wires to the Cardputer's EXT header pass here)
    translate([(outer[0] - pocket[0])/2 + ledge_w, (outer[1] - pocket[1])/2 + ledge_w, z_ledge - 1])
      cube([pocket[0] - 2*ledge_w, pocket[1] - 2*ledge_w, ledge_t + 2]);

    // Cardputer pocket
    translate([(outer[0] - pocket[0])/2, (outer[1] - pocket[1])/2, z_pocket])
      cube([pocket[0], pocket[1], pocket_d + 1]);

    // finger notches
    for (y = [0, outer[1]])
      translate([outer[0]/2, y, outer[2]]) rotate([90, 0, 0])
        cylinder(r = notch_r, h = wall * 4, center = true);

    for (c = cutouts) cutout(c);
  }

  // HAT standoffs
  for (h = hat_holes)
    translate([wall + clear + h[0], wall + clear + h[1], floor_t - 0.01])
      difference() {
        cylinder(d = standoff_d, h = standoff_h);
        cylinder(d = standoff_hole, h = standoff_h + 1);
      }
}

module ghosts_solid() {
  color("dimgray")   translate([(outer[0] - cp[0])/2, (outer[1] - cp[1])/2, z_pocket]) cube(cp);
  color("seagreen")  translate([wall + clear, wall + clear, floor_t + standoff_h]) cube([hat[0], hat[1], hat_pcb]);
  color("seagreen", 0.5) translate([wall + clear + 5, wall + clear + 5, floor_t + standoff_h + hat_pcb]) cube([hat[0] - 10, hat[1] - 10, hat_above]);
  color("orange")    translate([wall + 25, wall + 11, floor_t]) cube([60, 36, 7]);
  color("royalblue") translate([wall + 1, wall + 11, floor_t]) cube([22.9, 36.2, 9]);
}

/* ---------- optional ghost parts for checking fit (not printed) ---------- */
show_parts = false;
module ghosts() {
  // Cardputer
  %translate([(outer[0] - cp[0])/2, (outer[1] - cp[1])/2, z_pocket]) cube(cp);
  // HAT
  %translate([wall + clear, wall + clear, floor_t + standoff_h]) cube([hat[0], hat[1], hat_pcb + hat_above]);
  // battery 60 x 36 x 7 (e.g. 2000 mAh) and PowerBoost 1000C 36.2 x 22.9
  %translate([wall + 25, wall + 11, floor_t]) cube([60, 36, 7]);
  %translate([wall + 1, wall + 11, floor_t]) cube([22.9, 36.2, 9]);
}

section = false;   // true = cut away the front half to show the inside
if (section) {
  intersection() {
    union() { shell(); if (show_parts) ghosts_solid(); }
    translate([-1, outer[1]/2, -1]) cube([outer[0] + 2, outer[1], outer[2] + 2]);
  }
} else {
  shell();
  if (show_parts) ghosts();
}

echo(str("Outer size (mm): ", outer));
echo(str("Outer size (in): ", [for (v = outer) round(v / 25.4 * 100) / 100]));
