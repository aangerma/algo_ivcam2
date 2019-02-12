%%
Interdist:
1. Take subpixels from cb detection, minus one to start count from 0.   
2. Apply K matrix.

calibDFZ:
1. Calculate RTD by inverting the pipe. 
2. Calculate Angx / Angy by doing xy2angSF (and polyundist ^-1). This function translate 0-640 to -+ 2047.

