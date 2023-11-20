
with open('./TextModeMemoryFiles/cols.mem', 'w+') as fil:
    for i in range(0, 2400):
      fil.write(f"{0x0f:02x}\n")
