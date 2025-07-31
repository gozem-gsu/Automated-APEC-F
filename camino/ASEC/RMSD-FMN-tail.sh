#!/bin/bash
set -e

# Load variables
Project=$(grep "Project" ../../../Infos.dat | awk '{ print $2 }')
chromo=$(grep "chromo_FF_name" ../../../../parameters | awk '{ print $2 }')

gro_file="${Project}_box_sol.gro"
ndx_file="${Project}_fmn_tail.ndx"
group_name="FMN_TAIL"

tmp_indices="/tmp/fmn_indices_all.txt"
> "$tmp_indices"  # Empty the file

# Step 1: Get atom indices from C1' to O3P
inside_range=false
awk -v chromo="$chromo" '
{
    resname=substr($0, 6, 5)
    atomname=substr($0, 11, 5)
    gsub(/^ +| +$/, "", resname)
    gsub(/^ +| +$/, "", atomname)
    if (resname == chromo) {
        if (atomname == "C1'\''") inside_range=1
        if (inside_range) print NR - 2
        if (atomname == "O3P") inside_range=0
    }
}
' "$gro_file" >> "$tmp_indices"

# Step 2: Get atom indices from H10 to last CHR atom
start_recording=false
awk -v chromo="$chromo" '
{
    resname=substr($0, 6, 5)
    atomname=substr($0, 11, 5)
    gsub(/^ +| +$/, "", resname)
    gsub(/^ +| +$/, "", atomname)
    if (resname == chromo) {
        if (atomname == "H10") start_recording=1
        if (start_recording) print NR - 2
    }
}
' "$gro_file" >> "$tmp_indices"

# Step 3: Sort, deduplicate and write to .ndx file
sort -n "$tmp_indices" | uniq > /tmp/fmn_indices_clean.txt

echo "[ $group_name ]" > "$ndx_file"
awk '
{
    printf "%5d", $1
    if (NR % 15 == 0) printf "\n"
}
END { printf "\n" }
' /tmp/fmn_indices_clean.txt >> "$ndx_file"

# Optional: Merge with existing .ndx
cat ${Project}_box_sol.ndx "$ndx_file" > ${Project}_box_sol_with_tail.ndx

echo "✅ Group '$group_name' created in $ndx_file"

echo -e "0\n0" | gmx rms -f ${Project}_box_sol.xtc -s ${Project}_box_sol.tpr -n ${Project}_fmn_tail.ndx -o rms_fmn_tail.xvg

python3 plot-RMSD.py
