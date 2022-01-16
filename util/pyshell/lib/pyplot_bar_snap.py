import numpy as np
import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker


mpl.rcParams['font.family'] = '%%font_family'

# color define
colors=("#3498db","#51a62d","#1abc9c","#9b59b6","#f1c40f",
         "#7f8c8d","#34495e","#446cb3","#d24d57","#27ae60",
         "#663399","#f7ca18","#bdc3c7","#2c3e50","#d35400",
         "#9b59b6","#ecf0f1","#ecef57","#9a9a00","#8a6b0e")

# data load
datas=[%%datas]
labels=[%%labels]
l_xticks = []

# define png size
fig = plt.figure(figsize=(8,4), dpi=200)
ax = fig.add_subplot(111)

# define title
plt.title('%%title', fontsize=10)

# plot  by pylot instance
count=0
for data in datas:
  ax.bar(count, datas[count], color=colors[count], edgecolor='w', align='center', label=labels[count])
  l_xticks.append(count)
  count+=1

# define xticks
plt.xticks(l_xticks, labels)

# define  yticks
plt.yticks(fontsize = 8)

# defline label
plt.xlabel("%%X_label")
plt.ylabel("%%Y_label")

# export to png
plt.savefig("%%output") 
