
with open('./TextModeMemoryFiles/col_map.mem', 'w+') as fil:
    for i in range(0, 2400):
      if i % 4 == 0: fil.write("\n")
      fil.write(f"{0x0f:02x}")
