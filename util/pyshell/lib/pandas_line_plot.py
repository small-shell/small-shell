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
df = pd.read_csv("%%csv")
df.set_index('%%index',inplace=True) #index will be xticks
ax = df.plot(kind='line',rot=20, figsize=(15,7), legend=%%legend)

# labeling
ax.set_xlabel('%%X_label',size=12)
ax.set_ylabel('%%Y_label',size=12)

# add title
plt.title('%%title')

# export to png
plt.savefig("%%output") 
