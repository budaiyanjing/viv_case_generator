#!/bin/bash
# process boundary file

boundary_file="./constant/polyMesh/boundary"
sed -i -e '/^\s*ggi[0-9L]/, /}/ {/type/ s/patch/ggi/' -e '}' $boundary_file
for loop in `seq 20`; do
    eval "sed -i -e \"/^\\s*ggi${loop}in/,/}/ {/}/ i\\ \n\t\tshadowPatch\tggi${loop}out;\n\t\tzone\t\tggi${loop}inZone;\n\t\tbridgeOverlap\tfalse;\" -e '}' $boundary_file"
    eval "sed -i -e \"/^\\s*ggi${loop}out/,/}/ {/}/ i\\ \n\t\tshadowPatch\tggi${loop}in;\n\t\tzone\t\tggi${loop}outZone;\n\t\tbridgeOverlap\tfalse;\" -e '}' $boundary_file"
done
sed -i -e '/^\s*ggiLastout/,/}/ {/}/ i\ \n\t\tshadowPatch\tggiLastin;\n\t\tzone\t\tggiLastoutZone;\n\t\tbridgeOverlap\tfalse;' -e '}' $boundary_file
