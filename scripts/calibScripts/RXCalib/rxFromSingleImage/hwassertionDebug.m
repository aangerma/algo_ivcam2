%{
1. New IPDev- xml file as Tom wrote in his mail.
                        Z:\ASIC\ASIC_MA-A0\FLASH_IMAGES\FW_IVCAM2_1_1_3_7
                        Cp xml to IPDEV folder

2. In the HW Logger - assertion numbuer appears. (assertion status)
3. To make sure the number is right, you can use mrd command from
hhwa_tom.txt. (//HWA status)

For exmaple:
1820 -
   8 - the 11th bit - cbuf - use the cbuf status read command (got 3000 - bits 12-13) - cbuf underflow - In this case it is permitted (we ignore it), and we can mask this assertion.
               Read the mask bits, add ones at the status bits and mwd t
               back. In the config 3 file, we can write the new mask that
               masks the config.

