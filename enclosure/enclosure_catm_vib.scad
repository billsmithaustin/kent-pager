// Kent Pager: Unit CatM + Unit Vibrator belt-clip enclosure (draft).
// Matches enclosure_catm_vib_drawings.svg. Units: mm. Values marked MEASURE are guesses.
// Render options (set with -D on the command line):
show_cp    = false;  // Cardputer ghost
show_parts = true;   // Unit CatM, Unit Vibrator
show_dims  = true;   // dimension lines and labels
show_clip  = true;   // belt clip
dims_set   = 1;      // which set of dimensions to draw (1-4, one per view)
$fn = 48;

wall = 2; floor_t = 2; clear = 0.4; rim = 2; ledge_t = 2; proud = 1;
cp = [84, 54, 19.6];
pocket = [cp[0] + 2*clear, cp[1] + 2*clear];          // 84.8 x 54.8
W = pocket[0] + 2*wall; D = pocket[1] + 2*wall;       // 88.8 x 58.8
bay_h = 9; z_ledge = floor_t + bay_h; z_pocket = z_ledge + ledge_t;
H = z_pocket + cp[2] - proud;                          // 31.6
unit = [2.4, 32.4, 72, 24, 8];                         // Unit CatM x, y, w, d, h
vib  = [8, 5.4, 32, 24, 8];                            // Unit Vibrator
rail = [46, 30.4, 26, 1.6, 4];
notch_r = 9;
ant = [44.4, floor_t + 4, 3.5];                        // antenna hole y, z, r (left end) MEASURE
zc = z_pocket + cp[2]/2;
usb = [D/2, zc, 13, 7];                                // right end, MEASURE
sw  = [D/2 + 16, zc, 9, 5];                            // right end, MEASURE
clip = [W/2 - 15, D/2 - 27, 30, 54, 6];

module rrect(s, h, r) linear_extrude(h) offset(r) offset(-r) square(s);

module shell() color("#d8dde3") difference() {
  rrect([W, D], H, 3);
  translate([wall, wall, floor_t]) cube([pocket[0], pocket[1], bay_h + 0.01]);
  // chamfer under the ledge
  hull() {
    translate([wall, wall, z_ledge - 2]) cube([pocket[0], pocket[1], 0.01]);
    translate([wall + rim, wall + rim, z_ledge]) cube([pocket[0] - 2*rim, pocket[1] - 2*rim, 0.01]);
  }
  translate([wall + rim, wall + rim, z_ledge - 1]) cube([pocket[0] - 2*rim, pocket[1] - 2*rim, ledge_t + 2]);
  translate([wall, wall, z_pocket]) cube([pocket[0], pocket[1], H]);
  for (y = [0, D]) translate([W/2, y, H]) rotate([90, 0, 0]) cylinder(r = notch_r, h = 10, center = true);
  translate([-1, ant[0], ant[1]]) rotate([0, 90, 0]) cylinder(r = ant[2], h = wall + 2);
  for (c = [usb, sw]) translate([W - wall - 1, c[0] - c[2]/2, c[1] - c[3]/2]) cube([wall + 2, c[2], c[3]]);
}

module inside() {
  translate([rail[0], rail[1], floor_t - 0.01]) color("#d8dde3") cube([rail[2], rail[3], rail[4]]);
  if (show_parts) {
    translate([unit[0], unit[1], floor_t]) color("#3fa66b") cube([unit[2], unit[3], unit[4]]);
    translate([unit[0] - 1, unit[1] + unit[3]/2, floor_t + 4]) rotate([0, -90, 0]) color("gold") cylinder(r = 3.2, h = 4); // SMA
    translate([vib[0], vib[1], floor_t]) color("#f08a24") cube([vib[2], vib[3], vib[4]]);
  }
  if (show_clip) translate([clip[0], clip[1], -clip[4]]) color("#6d7680") rrect([clip[2], clip[3]], clip[4], 2);
  if (show_cp) translate([wall + clear, wall + clear, z_pocket]) {
    color("#2b2f36") cube(cp);
    // keyboard hint on top
    color("#555b66") for (i = [0:3], j = [0:13]) translate([4 + j*5.6, 4 + i*5.4, cp[2]]) cube([4.6, 4.4, 0.6]);
    color("#111") translate([20, 28, cp[2]]) cube([44, 22, 0.4]);
  }
}

/* ---------- dimensions ---------- */
dc = "#1f4e8c"; ts = 4.6;
// dimension along +x of length L, in the XY plane, text above (+y)
module dimx(L, label, flip = false, sz = ts) color(dc) {
  translate([0, -0.3, 0]) cube([L, 0.6, 0.6]);
  for (e = [[0, 0], [L, 180]]) translate([e[0], 0, 0.3]) rotate([0, 0, e[1]]) rotate([0, 90, 0]) cylinder(r1 = 1.4, r2 = 0, h = 4.5);
  for (x = [0, L]) translate([x - 0.3, -3, 0]) cube([0.6, 6, 0.6]);
  translate([L/2, flip ? -2.2 : 2.2, 0]) linear_extrude(0.6) text(label, size = sz, halign = "center", valign = flip ? "top" : "bottom", font = "Helvetica:style=Bold");
}
module dim(p, rot, L, label, flip = false, sz = ts) translate(p) rotate(rot) dimx(L, label, flip, sz);

function f2(x) = let(c = round(x * 100)) str(floor(c / 100), ".", c % 100 < 10 ? "0" : "", c % 100);
function inch(v) = str(v, " mm (", f2(v / 25.4), " in)");
module lbl(p, rot, t, sz = ts, ha = "center") color(dc) translate(p) rotate(rot)
  linear_extrude(0.6) text(t, size = sz, halign = ha, valign = "center", font = "Helvetica:style=Bold");
vert = [90, -90, 0];     // dimension running up the front face
rface = [90, 0, 90];     // text on the right end, read from outside
lface = [90, 0, -90];    // text on the left end, read from outside

module dims() {
  if (dims_set == 1) {        // front-left-top
    dim([0, -10, 0], [0, 0, 0], W, inch(W), true);
    dim([-10, D, 0], [0, 0, -90], D, inch(D), true);
    dim([W + 7, -7, 0], vert, H, inch(H));
    lbl([W/2, -0.7, H - notch_r - 5], [90, 0, 0], "Finger notch both sides", 3.6);
  }
  if (dims_set == 2) {        // front-right-top, Cardputer fitted
    dim([-7, -7, -clip[4]], vert, H + clip[4], inch(H + clip[4]));
    lbl([W + 0.7, usb[0] - 2, usb[1] - 7.5], rface, "Cardputer USB-C", 3.8);
    lbl([W + 0.7, sw[0] + 2, sw[1] + 6.5], rface, "Switch", 3.8);
  }
  if (dims_set == 3) {        // looking down inside, Cardputer removed
    dim([unit[0], unit[1] + 5, floor_t + unit[4] + 0.1], [0, 0, 0], unit[2], "Unit CatM 72 mm", false, 3.4);
    dim([unit[0] + unit[2] + 3, unit[1], floor_t + 0.1], [0, 0, 90], unit[3], "24", true, 3.4);
    dim([vib[0], vib[1] + 5, floor_t + vib[4] + 0.1], [0, 0, 0], vib[2], "Vibrator 32", false, 3.4);
    dim([vib[0] + vib[2] + 3, vib[1], floor_t + 0.1], [0, 0, 90], vib[3], "24", true, 3.4);
    lbl([rail[0] + rail[2]/2, rail[1] - 3.5, floor_t + rail[4] + 0.1], [0, 0, 0], "Rail", 3.2);
    lbl([W/2 + 21, 21, floor_t + 0.1], [0, 0, 0], "Bay 9 mm deep", 3.2);
  }
  if (dims_set == 4) {        // from below and behind
    dim([clip[0] + clip[2], clip[1] + clip[3] + 6, -clip[4]], [180, 0, 180], clip[2], "Clip 30 mm");
    dim([clip[0] - 6, clip[1], -clip[4]], [180, 0, 90], clip[3], "54 mm", true);
    lbl([W/2, D + 0.7, 12], [90, 0, 180], "Belt clip 6 mm thick, screwed to floor", 3.6);
  }
}

shell();
inside();
if (show_dims) dims();
