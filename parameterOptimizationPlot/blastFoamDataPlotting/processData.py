'''Imports'''
import os
import numpy as np
from pathlib import Path
import pandas as pd 
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter
from PIL import Image
import io

'''Set filenames'''
dataDirName = "data10kg/"
dataNames = "df10kg."
dataExt = ".csv"

'''Count number of rows in each file'''
# for i in range(10):
#     df = dataNames + str(i) + dataExt
#     print(df)

# Sort key 
# - https://stackoverflow.com/questions/7304117/split-filenames-with-python
# - https://stackoverflow.com/questions/33159106/sort-filenames-in-directory-in-ascending-order
def extract_number(file_path):
    # For an example input of "df.10.csv" ...
    # .stem - takes off extension "df.10"
    # .split('.')[1] - splits into two elements "df" and "10" surrounding the ".", then selects the second element "10"
    return int(file_path.stem.split('.')[1])
dfNames = sorted(Path(dataDirName).glob('*.csv'), key=extract_number)
# test = dfNames[1]
# test3 = test.name

# Get number of data files
N = len(dfNames)

# Get data file names in a separate list
dfNamesList = [file.name for file in dfNames]
# print(dataDirName + dfNamesList[1])

# # Get number of rows for each file - https://stackoverflow.com/questions/16108526/how-to-obtain-the-total-numbers-of-rows-from-a-csv-file-in-python
# #   to make sure they're all the same length
# rows = []
# cols = []
# for i in range(N):
#     rows.append(pd.read_csv(dataDirName + dfNamesList[i]).shape[0])
#     cols.append(pd.read_csv(dataDirName + dfNamesList[i]).shape[1])
# # cols.append(5)

# # Check that all of them are the same number of rows
# avgRows = np.mean(rows)
# avgCols = np.mean(cols)
# # if avgRows != rows[0] or avgCols != cols[0]:
# #     print("          Some files have inconsistent dimensions.  \n\
# #           The average numer of rows is %d, and the first file has %d rows. \n\
# #           The average numer of columns is %d, and the first file has %d columns." % (avgRows, rows[0], avgCols, cols[0]))
# #     # raise
# # else:
# M = rows[0]


'''Gather all csv data into a variable for easy plotting'''
N = 1246
M = 30001

# Set times
dt = 0.0001
times = dt + np.arange(0,N) * dt

# Set desired column names
desData = ["overpressure", "U:0", "U:1", "U:2", "Points:0", "Points:1"]

# Initialize arrays
overpressure = np.zeros((M,N))
u0 = np.zeros((M,N))
u1 = np.zeros((M,N))
u2 = np.zeros((M,N))
x = np.zeros((M,N))
y = np.zeros((M,N))
timeOfArrival = np.zeros((M,N))

# Get data
for i in range(N):
    data = pd.read_csv(dataDirName + dfNamesList[i], usecols = desData)
    # test = data[desData]
    overpressure[:, i], u0[:, i], u1[:, i], u2[:, i], x[:, i], y[:, i], timeOfArrival[:, i] = data[desData].values.T

r = np.hypot(x[:, 0], y[:, 0])

'''Save the organized data into csv's'''
processedDFN = 'processedData10kgFine/'
os.makedirs(processedDFN,exist_ok=True)

# overpressure
op = pd.DataFrame(overpressure)
op.to_csv(processedDFN + "overpressure.csv")

# umag
mag = pd.DataFrame(np.hypot(u0,u1,u2))
mag.to_csv(processedDFN + "Umag.csv")

# time
time = pd.DataFrame(times)
time.to_csv(processedDFN + "times.csv")

# radii
radii = pd.DataFrame(np.hypot(x,y))
radii.to_csv(processedDFN + "radii.csv")