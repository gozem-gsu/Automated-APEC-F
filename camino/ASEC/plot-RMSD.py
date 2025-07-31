import matplotlib.pyplot as plt

# Load data from GROMACS .xvg RMSD file
filename = "rms_fmn_tail.xvg"

times = []
rmsd = []

with open(filename) as f:
    for line in f:
        if line.startswith(('#', '@')):
            continue
        parts = line.split()
        times.append(float(parts[0]))
        rmsd.append(float(parts[1]))

plt.figure(figsize=(8,5))
plt.plot(times, rmsd, label='FMN Tail RMSD')
plt.xlabel('Time (ps)')
plt.ylabel('RMSD (nm)')
plt.title('RMSD of FMN Tail')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig('rms_fmn_tail.png')
plt.show()
