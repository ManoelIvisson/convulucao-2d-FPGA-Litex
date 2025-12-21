import serial
import time

ser = serial.Serial("/dev/ttyACM0", 115200)
time.sleep(2)

with open("image_in.hex") as f:
  for line in f:
    px = int(line.strip(), 16)
    ser.write(bytes([px]))
