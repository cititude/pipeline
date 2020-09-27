import numpy as np
ub = 2 ** 31 - 1;
with open("data.txt","w") as f:
    for i in range(128):
        x = np.random.randint(0, ub)
        x=hex(x)[2:].zfill(8)
        print(x[0:2],x[2:4],x[4:6],x[6:8],file=f)
    s=  "00 00 00 3f\n" + \
        "00 00 00 06\n" + \
        "00 00 00 5b\n" + \
        "00 00 00 4f\n" + \
        "00 00 00 66\n" + \
        "00 00 00 6d\n" + \
        "00 00 00 7d\n" + \
        "00 00 00 07\n" + \
        "00 00 00 7f\n" + \
        "00 00 00 6f\n" + \
        "00 00 00 77\n" + \
        "00 00 00 7c\n" + \
        "00 00 00 39\n" + \
        "00 00 00 5e\n" + \
        "00 00 00 7b\n" + \
        "00 00 00 71\n"
    print(s,file=f)