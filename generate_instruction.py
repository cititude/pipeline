import re
with open("instruction.txt", "w") as fw:
    with open("inst.txt", "r") as fr:
        lines = fr.readlines()
        for line in lines:
            print(line)
            if (line.startswith("081")):
                line=list(line)
                line[2] = '0'
                line=''.join(line)
            if (line.startswith("0c1")):
                line=list(line)
                line[2] = '0'
                line = ''.join(line)
            line = re.sub(r"(?<=\w)(?=(?:\w\w)+$)", " ", line)
            print(line.strip(), file=fw)