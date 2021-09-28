/*
 One segment of a ring-type habitat, rotated about the X axis.
 
 Separately models the interior pressure vessel and exterior walls. 
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2021-09-27 (Public Domain)
*/

$fs=0.01; $fa=3; 

// File units are *meters*

// Inside diameter of pressure vessel
pressureID=9.0;  // <- diameter of one Starship orbiter

// Wall thickness between inside and outside of habitat
wall=0.7; // <- micrometeorite, secondary pressure vessel, thermal control, etc.

// Exterior dimensions
habOD=wall+pressureID+wall;

// Distance between floor of habitat and rotational axis
//   Compute the gravity produced via  https://www.artificial-gravity.com/sw/SpinCalc/
spinZ=30;

// Segment of a circle, in degrees, that our habitat covers.
//   You want segments, not a full ring, for disaster tolerance.
segment=40; 

// Distance between bottom of pressure vessel (sump) and working floor
//   This determines the floor area
sumpZ=2.3;

// Centerline is the height above floor of middle of pressure vessel
centerline=pressureID/2 - sumpZ;

// If 1, do a segmented outside surface.
//   If 0, do a smooth outside surface.
segmented=1;

// Living space cross section
module living2D() {
    intersection() {
        // Rounded walls
        translate([0,centerline]) circle(d=pressureID);

        // Flat floor
        translate([0,pressureID]) 
            square([2*pressureID,2*pressureID],center=true);
    }
}

// Outside cross section.  The $fn is purely aesthetic
module outside2D() {
    if (segmented) 
    {
        // Segmented flat-sides version (lower poly)
        translate([0,centerline]) rotate([0,0,360/8/2]) circle(d=habOD,$fn=8);
    }
    else {
        // Smooth tube version
        translate([0,centerline]) circle(d=habOD);
    }
}

// Rotate-extrude this 2D object into 3D,
//   curved around the X axis at height spinZ.
module spinShape2D() {
    rotate([0,90,0])
        rotate([0,0,-(segment+0.001)/2]) // center the angle range
        rotate_extrude(angle=segment+0.001)
            translate([spinZ,0,0])
            rotate([0,0,90]) // <- we want to rotate around X, not Y
                children();
}

// Spin this far around this segment: -1 for -Y end, +1 for +Y end
module spinDistance(spin)
{
    rotate([spin*segment/2,0,0])
    translate([0,0,-spinZ])
        children();
}

// Make this feature at both ends of the segment
module bothEnds() 
{
    for (end=[-1,+1]) 
        spinDistance(end) scale([1,end,1]) 
            children();
}

// Take this 2D cross section and make a hab out of it:
//   spin the middle, add rounded endcaps.
module habShape2D() {
    // Middle:
    spinShape2D() children();
    
    // Endcaps:
    if (segment<360.0)
    bothEnds()
        rotate_extrude(angle=180,$fa=5)
            intersection() {
                children();
                // We only keep the right side of the shape
                translate([pressureID+0.0001,0]) 
                    square([2*pressureID,2*pressureID],center=true);
            }
}

// Connection between habs is a simple cylinder
module habJoin(h,extraWall) {
    habJoinOD=3;
    translate([0,0,habJoinOD/2]) 
        rotate([-90,0,0])
            cylinder(d=habJoinOD+2*extraWall,h=h);
}

// Row of windows along hab
module habWindows()
{
    for (w=[-1:0.25:+1]) spinDistance(w)
        translate([0,0,centerline])
        rotate([0,90,0]) scale([1,0.5,1]) 
            cylinder(h=habOD+1,center=true,d=2.5,$fa=15);
}

module habOutside()
{
    habShape2D() outside2D();
    bothEnds() habJoin(habOD/2+0.1,wall);
}
module habInside()
{
    habShape2D() living2D();
    bothEnds() habJoin(pressureID/2,0);
}

module fullHab()
{
    difference() {
        habOutside();
        habInside();
        habWindows();
        
        // Cutaway
        //cube([100,100,100]);
    }
}

//rotate([90,0,0]) living2D();
fullHab();




