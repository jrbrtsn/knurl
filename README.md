# ban2fail

(C) 2022 John D. Robertson <john@rrci.com>

**knurl** is a very simple command line program to assist machinists in
choosing a stock diameter that will knurl correctly.

To use the program, edit 'knurl.c' to specify the knurl wheel pitch you are
using, as well as a range of stock diameter you find acceptable. Compile and
run the program, and you will see output like this:

```
knurl wheel pitch= 2.0 mm, min stock diameter= 0.750 inch, max diameter= 1.000 inch
dia= 0.978 inch
dia= 0.953 inch
dia= 0.928 inch
dia= 0.903 inch
dia= 0.878 inch
dia= 0.777 inch
dia= 0.752 inch
```

In this case you could choose to turn your stock to .978" diameter before
knurling, or any of the other diameters listed.

Happy knurling!
