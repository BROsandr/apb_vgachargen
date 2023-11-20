
with open('./TextModeMemoryFiles/characterBuffer80x60.mem', 'w+') as fil:
    for i in range(0, 2400):
      fil.write(f"{i%256:02x}\n")
