import pandas as pd
import matplotlib.pyplot as plt

mpl.rcParams['font.family'] = '%%font_family'

# ---------------------------------------------------------------------
# pie graph
# ---------------------------------------------------------------------
df = pd.read_csv("%%csv")
df.set_index('%%index',inplace=True) 
ax = df.plot.pie(subplots=True, figsize=(11, 6), autopct="%1.1f%%")

# add title
plt.title('%%title')

# export to png
plt.savefig("%%output")
