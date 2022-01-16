import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np

mpl.rcParams['font.family'] = '%%font_family'

# color define
c_cycle=("#3498db","#51a62d","#1abc9c","#9b59b6","#f1c40f",
         "#7f8c8d","#34495e","#446cb3","#d24d57","#27ae60",
         "#663399","#f7ca18","#bdc3c7","#2c3e50","#d35400",
         "#9b59b6","#ecf0f1","#ecef57","#9a9a00","#8a6b0e")

# insert data
datas=[%%datas]
labels=[%%labels]

plt.style.use('ggplot')
plt.rcParams.update({'font.size':15})

# gen pie graph
plt.figure(figsize=(15, 7),dpi=100)
plt.pie(datas,colors=c_cycle,counterclock=False,startangle=90,autopct=lambda p:'{:.1f}%'.format(p) if p>=5 else '')
plt.subplots_adjust(left=0,right=0.7)
plt.legend(labels,fancybox=True,loc='center left',bbox_to_anchor=(0.9,0.5))
plt.title('%%title', fontsize=12 )
plt.axis('equal') 
plt.savefig('%%output',bbox_inches='tight',pad_inches=0.05)
