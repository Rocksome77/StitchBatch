# StitchBatch
ImageJ scripting to automate the Grid Stitch tool for large number of images output via direct Columbus export.

Medium throughput microscopy pacakges Colombus amd Harmony both export their images in a strange numbering system where image #1 is an image from the centre of the well
and subsequent the numbering starts at #2 in the top-left, then snakes from left-to-right then right-to left, skipping image #1.
This is an ImageJ script that renames all the images starting from #1 in the top-left, stitches the images in every colour channel together using the Grid Stitch package
and then overlays each individual stitched colour channel into a single multi-channel image.
Images are loaded using the Colmbus generalised image naming format: "00y00x-f-00t00z00c.tif"
where y is the row, x  is the column, f is the field of view, t is the time series, z is the vertical stack position and c is the colour channel. Currently only implemented for 
time point 1 and z-position 1.
