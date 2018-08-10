# APDL Debugger tool to verify flow control commands and keywords in APDL code; ver. 2.2 (based on ANSYS v.17)

## Description
Tool generates file <tabulated.inp> with re-tabulated code according to its structure. 
Lines with I/O data format [eg. (f4,f4)] are adjusted to left.
To exclude part of code from debugging wrap it by !!!DEBUG_OFF!!! and !!!DEBUG_ON!!! tags.
 													
## Usage in Textpad:
Copy this file to local disk (FULL_PATH\APDL.awk)
Configure Textpad menu Tools > Run... :
  Command: C:\Apps\cygwin\bin\awk.exe
  Parameter: -f FULL_PATH\APDL.awk $File
  Initial folder: $FileDir
  Check option 'Capture output'
To verify apdl script click Tools > Run > OK and check output window.
