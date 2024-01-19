import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt

mpl.rcParams['font.family'] = '%%font_family'

# ---------------------------------------------------------------------
# line graph
# ---------------------------------------------------------------------
#df = pd.read_csv("./tmp.csv", parse_dates=['date'])
#df.set_index('date',inplace=True) #index will be xticks
#ax = df.plot(kind='line',rot=20, figsize=(15,7))

# ---------------------------------------------------------------------
# set major ticks format for line
# ---------------------------------------------------------------------
#ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
#ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))
#ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d\n%H:%M:%S"))
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# bar graph
# ---------------------------------------------------------------------
df = pd.read_csv("./tmp.csv")
df.set_index('date',inplace=True) #index will be xticks
ax = df.plot(kind='bar',rot=80, figsize=(20,12))

# ---------------------------------------------------------------------
# COMMON
# ---------------------------------------------------------------------

# labeling
ax.set_xlabel('x label',size=12)
ax.set_ylabel('y label',size=12)

# export to png
plt.savefig("daily_figure.png") 
