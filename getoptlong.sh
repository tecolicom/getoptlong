export PERL5LIB=$(pwd)/lib:$PERL5LIB

ansiecho=ansiecho

declare -a opts=(--separate $'\n')
init() {
    opts=(--separate $'\n')
}

declare -a H=($(seq 5 60 359))

table() {
    local mod=$1
    for s in 100
    do
	for h in ${H[@]}
	do
	    opts+=("(h=$h, s=$s)")
	    for l in $(seq 5 5 99)
	    do
		col=$(printf "hsl(%03d,%03d,%03d)" $h $s $l)
		arg="$col$mod/$col"
		opts+=(-c "$arg" "$col$mod")
	    done
	done
	$ansiecho "${opts[@]}" | ansicolumn -C ${#H[@]} --cu=1 --margin=0
	init
    done
}

for mod in %l50 %y51 %y50+h180 %y50+r180 %y50+h30 %y50+r30
do
    table $mod
done
