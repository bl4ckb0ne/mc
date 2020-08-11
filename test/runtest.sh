#!/bin/sh
export PATH=$(pwd):$PATH
export MYR_MC=$(cd ..; pwd)/6/6m
export MYR_MUSE=$(cd ..; pwd)/muse/muse
ARGS=$*
NFAILURES=0
NPASSES=0

build() {
	dir=$(echo $1 | egrep -o '.*/')
	if [ -z $dir ]; then
		rm -f out/$1 out/$1.o out/$1.s out/$1.use
		mkdir -p out
		../obj/mbld/mbld -Bnone -o 'out' -b $1 -I../obj/lib/std -I../obj/lib/sys -I../obj/lib/regex -r../rt/_myrrt.o $1.myr
	else
		target=$(echo $1 | egrep -o '[^/]*$')
		top=$(pwd)
		mkdir -p out/$dir
		cd $dir
		$top/../obj/mbld/mbld -Bnone -o $top/out/$dir -I$top/../obj/lib/std -I$top/../obj/lib/sys -I$top/../obj/lib/regex -r$top/../rt/_myrrt.o clean
		$top/../obj/mbld/mbld -Bnone -o $top/out/$dir -I$top/../obj/lib/std -I$top/../obj/lib/sys -I$top/../obj/lib/regex -r$top/../rt/_myrrt.o :$target
	fi
}

pass() {
	PASSED="$PASSED $1"
	NPASSED=$(($NPASSED + 1))
	echo "!}>> ok"
}

fail() {
	FAILED="$FAILED $1"
	NFAILED=$(($NFAILED + 1))
	echo "!}>> fail $1"
}

expectstatus() {
	./out/$1 $3
	if [ $? -eq $2 ]; then
		pass $1
		return
	else
		fail $1
	fi
}

expectprint() {
	if [ "`./out/$1 $3`" != "$2" ]; then
		fail $1
	else
		pass $1
	fi
}

expectcompare() {
	if [ x"" !=  x"$TMPDIR" ]; then 
		t=$TMPDIR/myrtest-$1-$RANDOM
	else
		t=/tmp/myrtest-$1-$RANDOM
	fi
	./out/$1 $3 > $t
	if cmp $t data/$1-expected; then
		pass $1
	else
		fail $1
	fi
	rm -f $t
}

expectfcompare() {
	./out/$1 $3
	if cmp data/$1-expected $2; then
		pass $1
	else
		fail $1
	fi
}

belongto() {
	elem="$1"; shift
	subset="$1"; shift

	IFS=','
	for v in $subset; do
		if [ "$elem" = "$v" ]; then
			return 0
		fi
	done
	return 1
}

# Should build and run
B() {
	test="$1"; shift
	type="$1"; shift

	if [ -n "$MTEST_SUBSET" ] && ! belongto "$test" "$MTEST_SUBSET"; then
		return 1
	fi

	if [ $# -gt 0 ]; then
		res="$1"; shift
	fi
	if [ $# -gt 0 ]; then
		args="$1"; shift
	fi
	echo "test $test <<{!"
	here=$(pwd)
	build $test
	cd $here
	case $type in
	"E")  expectstatus "$test" "$res";;
	"P")  expectprint "$test" "$res";;
	"C")  expectcompare "$test" "$res";;
	"F")  expectfcompare "$test" "$res" "$args";;
	esac
}

# Should fail
F() {
	if [ -n "$MTEST_SUBSET" ] && ! belongto "$test" "$MTEST_SUBSET"; then
		return 1
	fi

	echo "test $1 <<{!"
	here=$(pwd)
	(build $1) > /dev/null 2>&1
	if [ $? -eq '1' ]; then
		pass $1
	else
		fail $1
	fi
	cd $here
}

echo "MTEST $(egrep '^[BF]' tests | wc -l)"
. tests

echo "PASSED ($NPASSED): $PASSED"
if [ -z "$NFAILED" ]; then
	echo "SUCCESS"
else
	echo "FAILURES ($NFAILED): $FAILED"
	exit 1
fi
