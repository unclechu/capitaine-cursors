#!/bin/bash

# Capitaine cursors, macOS inspired cursors based on KDE Breeze
# Copyright (c) 2016 Keefer Rourke <keefer.rourke@gmail.com>
# Modified to include white cursors by Efus10n - 4 Mar 2019
# Modified to make left-handed cursors by unclechu - 15 June 2019

function create {
	# constants
	local SIZES=(32 40 48 64) SIZE_DIRS=(x1 x1_25 x1_5 x2) TO_FLOP=(
		alias color-picker context-menu copy default dnd-move dnd-no-drop draft
		help no-drop openhand pencil progress pointer right_ptr wait
	)

	cd "$SRC"
	mkdir -p "${SIZE_DIRS[@]}"
	cd "$SRC"/$1

	local ALL_NAMES=($(
		find . -name '*.svg' -type f \
			-exec sh -c 'echo ${0%.svg} | sed "s|\./||"' {} \;
	))

	parallel \
		$'sh -c \'inkscape -z -e "../$1/$2.png" -w $0 -h $0 $2.svg\'' \
		::: "${SIZES[@]}" :::+ "${SIZE_DIRS[@]}" ::: "${ALL_NAMES[@]}"

	local to_flop_files=()
	for name in "${ALL_NAMES[@]}"; do
		for flop in "${TO_FLOP[@]}"; do
			if [[ $name =~ ^${flop}(-[0-9]{2})?$ ]]; then
				for dir in "${SIZE_DIRS[@]}"; do
					to_flop_files+=(../$dir/$name.png)
				done
			fi
		done
	done
	parallel convert {} -flop {} ::: "${to_flop_files[@]}"

	cd $SRC

	# generate cursors
	if [[ "$THEME" =~ White$ ]]; then
		BUILD="$SRC"/../dist-white
	else BUILD="$SRC"/../dist
	fi
	OUTPUT="$BUILD"/cursors
	ALIASES="$SRC"/cursorList
	FLOPPED_CONFIG_DIR=config-flopped

	if [ ! -d "$BUILD" ]; then
		mkdir "$BUILD"
	fi
	if [ ! -d "$OUTPUT" ]; then
		mkdir "$OUTPUT"
	fi
	if [ ! -d "$FLOPPED_CONFIG_DIR" ]; then
		mkdir "$FLOPPED_CONFIG_DIR"
	fi

	echo -ne "Generating cursor theme...\\r"
	for CUR in config/*.cursor; do
		BASENAME="$CUR"
		BASENAME="${BASENAME##*/}"
		BASENAME="${BASENAME%.*}"

		local cur_flopped=$(
			for name in "${TO_FLOP[@]}"; do
				if [[ $name == $BASENAME ]]; then
					cfg="$FLOPPED_CONFIG_DIR"/"$name".cursor
					echo "$cfg"
					cp "$CUR" "$cfg"
					perl -p -i -e '
						if(m/^24 (\d+)/){$x=32-$1-1;s/^24 (\d+)/24 $x/;next}
						if(m/^30 (\d+)/){$x=40-$1-1;s/^30 (\d+)/30 $x/;next}
						if(m/^36 (\d+)/){$x=48-$1-1;s/^36 (\d+)/36 $x/;next}
						if(m/^48 (\d+)/){$x=64-$1-1;s/^48 (\d+)/48 $x/;next}
					' "$cfg"
				fi
			done
		)

		local CONFIG_FILE=$(
			[[ -n $cur_flopped ]] && echo "$cur_flopped" || echo "$CUR"
		)

		xcursorgen "$CONFIG_FILE" "$OUTPUT/$BASENAME"
	done
	echo -e "Generating cursor theme... DONE"

	cd "$OUTPUT"

	#generate aliases
	echo -ne "Generating shortcuts...\\r"
	while read ALIAS; do
		FROM="${ALIAS#* }"
		TO="${ALIAS% *}"

		if [ -e $TO ]; then
			continue
		fi
		ln -sr "$FROM" "$TO"
	done < "$ALIASES"
	echo -e "Generating shortcuts... DONE"

	cd "$PWD"

	echo -ne "Generating Theme Index...\\r"
	INDEX="$OUTPUT/../index.theme"
	if [ ! -e "$OUTPUT/../$INDEX" ]; then
		touch "$INDEX"
		echo -e "[Icon Theme]\nName=$THEME\n" > "$INDEX"
	fi
	echo -e "Generating Theme Index... DONE"
}

# generate pixmaps from svg source
SRC=$PWD/src
THEME="Capitaine Cursors"

create svg

THEME="Capitaine Cursors - White"

create svg-white
