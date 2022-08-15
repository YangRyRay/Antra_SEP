import csv
import glob

datapath = "people"

input_files = glob.glob(datapath+"/*")

output = set()

for f in input_files:
    with open(f) as file:
        tsv_val = csv.reader(file, delimiter="\t")
        next(tsv_val)
        for line in tsv_val:
            line[0] = line[0].upper().strip()
            line[1] = line[1].upper().strip()
            line[2] = line[2].strip()
            line[3] = line[3].replace('-', '')
            line[4] = line[4].lstrip(" No.#")

            output.add(tuple(line))

with open("people_cleaned.csv", 'w') as out:
    writer = csv.writer(out)
    writer.writerows(output)