import serial
import time
import datetime
import numpy as np
import os

'''
Author:     Paul Kullmann
Purpose:    Record two-axis accelerometer data from Arduino for project preliminary data testing
Modified:   10/13/25

This is basically defunct since you can just read serial data in matlab, bypassing this python step
'''

data = []
duration = 10
directory = '/users/paulkullmann/Desktop/acc_data.csv'

def ardInit():
    connectedPort='/dev/cu.usbmodem101'
    print("ard inited")
    ser = serial.Serial(port=connectedPort, baudrate=9600, timeout=1)
    return(ser)

def main():
    ser = ardInit()
    startTime = time.time()
    global data
    while time.time() - startTime < duration:
        #print(str(time.time()-startTime))
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            if line:
                try:
                    x_data, y_data = map(int, line.split(','))
                    ts = time.time() - startTime
                    data.append([ts, x_data, y_data])
                except ValueError:
                    print(f"Bad data: {line}")
    saveData()

def saveData():
    with open(directory,'w') as f:
        for entry in data:
            f.write(','.join(map(str, entry))+'\n')
    print('Data saved to csv'+directory)


main()