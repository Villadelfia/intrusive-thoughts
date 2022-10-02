import csv
data = set()
with open('export.csv', newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if(row['Status'] == 'Complete'):
            data.add(row['ToKey'])

print('module.exports = [')
for l in data: print(f"    \"{l}\",")
print("];")
