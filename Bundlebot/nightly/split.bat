sed "/SCAN SUMMARY/,$ d" "%INPUT%" > "%OUT1%"
sed -n "/SCAN SUMMARY/,$ p" "%INPUT%" > "%OUT2%"