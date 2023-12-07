
with open('./TextModeMemoryFiles/col_map.mem', 'w+') as fil:
    s = []
    for i in range(0, 2400):
      if i % 4 == 0:
          s = s[::-1]
          fil.write(f"{''.join(map(str, s))}\n")
          s = []
      s.append(f"{0x90:02x}")
