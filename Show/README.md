TexMorph
===========

TexMorph is a simple IOS app that does a slideshow by simultaneously crossfading and deforming textured meshes.

Given an image, the program chooses four 'control points' that are inset from each of the image's corners.
During the animation from one image to another, it drags these control points to new positions, and the rest of
the image is dragged along with them, causing the image to distort.
The program overlays a grid mesh on the image, and each vertex of the grid is influenced by the control points.
Those points that are closest to a vertex will have a greater influence on the vertex's position.
In addition to the four control points, each vertex is also influenced by the four sides of the image; specifically,
by the perpendicular projections of the vertex to each of the sides.  This causes the vertices on (or near) the edges
to remain 'stuck' to the edges.

Tapping on the image activates certain debug features.  If you view the image as a 2x3 grid (two cells wide by three tall),
then tapping in one of these cells does one of the following:

 * pauses the animation
 * single-steps the animation
 * displays the geometry of the mesh
 * shrinks the images
 * skips immediately to the next image

Written by Jeff Sember, April 2013.

