set term postscript landscape
set title "Access to the Sulfolobus Database"
set data style fsteps
set xlabel "Date"
set timefmt "%d/%m/%y"
set yrange [ 0 : ]
set xdata time
set xrange [ "1/7/05":"1/8/05" ]
set ylabel "Number of times accessed"
set format x "%d/%m/%y"
set grid
set key left
plot  'access' using 1:2 t '' with lines
pause -1 'Test <Return> '
reset
