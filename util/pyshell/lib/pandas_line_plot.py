import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

mpl.rcParams['font.family'] = '%%font_family'

# ---------------------------------------------------------------------
# line graph
# ---------------------------------------------------------------------
df = pd.read_csv("%%csv", parse_dates=['Time'], encoding="utf-8")
df.set_index('Time',inplace=True) #index will be xticks
ax = df.plot(kind='line',rot=20, figsize=(15,7))

# ---------------------------------------------------------------------
# set major ticks format for line
# ---------------------------------------------------------------------
%%axasis
#ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
#ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))
#ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d %H:%M:%S"))
# ---------------------------------------------------------------------

# labeling
ax.set_xlabel('%%X_label',size=12)
ax.set_ylabel('%%Y_label',size=12)

# add title
plt.title('%%title')

# export to png
plt.savefig("%%output") 
