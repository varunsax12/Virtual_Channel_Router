import os
import re
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams['font.size'] = 12.0

arbiters = ["roundrob", "mat"]
arbiter_name = ["RoundRobin", "Matrix"]
allocators = ["sep", "wave"]
allocator_name = ["Separable", "Wavefront"]

legends = ["sequential", "inverter", "buffer", "logic", "physical_cells"]
colours = ['pink', 'skyblue', 'lightgreen', 'yellow', 'red', 'peachpuff', 'darkorange', 'lightseagreen', 'lavender']
def func(pct):
  return "{:1.1f}%".format(pct)


fig, axs = plt.subplots(2, 2)

x = 0
y = 0
for arb in arbiters:
    x = 0
    for alloc in allocators:
        temp_arr = []
        name = "alloc_{}_arbit_{}".format(alloc, arb)
        file_path = os.path.join("reports", name, "cell.rep")
        start_parse = False
        with open(file_path) as FH:
            for line in FH.readlines():
                line = line.rstrip()
                line = re.sub("\s+", " ", line)
                line = line.split(" ")
                if line[0] in legends:
                    val = line[-1]
                    temp_arr.append(float(val))
        plot_val = []
        plot_legends = []
        plot_color = []
        for i in range(0, len(legends)):
            if temp_arr[i] != 0.0:
                plot_val.append(temp_arr[i])
                plot_legends.append(legends[i])
                plot_color.append(colours[i])
        axs[x, y].pie(plot_val, colors=plot_color, autopct=lambda pct: func(pct), pctdistance=1.25)
        axs[x, y].set_title("{} Allocator \n {} Arbiter".format(allocator_name[x], arbiter_name[y]), fontsize=12, fontweight='bold')
        x += 1
    y += 1
plt.legend(plot_legends, bbox_to_anchor=(0.95, 0.00),
          ncol=5, fancybox=True, shadow=True)
# plt.tight_layout()
# plt.show()
plt.savefig('area_rep.png', bbox_inches="tight")