#!/bin/bash

GAME_TYPE="WII_GENERIC"
GAME_NAME="New Super Mario Bros. Wii"

show_notes () {

echo -e \
"************************************************
${GAME_NAME}

Custom New Super Mario Bros. Wii

Source:			Various
Base Image:		New Super Mario Bros. Wii (SMN?01)
Supported Versions:	EUR, JAP, USA
************************************************"

}

check_input_image_special () {

	check_input_image_nsmb
	ask_input_image_nsmb ${IMAGE%/*}
	echo -e "type SMN???.wbfs:\n"
	read ID

	if [[ ! -f ${IMAGE%/*}/${ID} ]]; then
		echo "wrong id from user-input given."
		exit 75
	fi

}

pi_action () {

	check_input_image_special

	if [[ -f ${HOME}/.patchimage.choice ]]; then
		echo "Your choices from last time can be re-used."
		echo "y (yes) or n (no)"
		read choice

		if [[ ${choice} == y ]]; then
			source ${HOME}/.patchimage.choice
		fi
	fi

	if [[ ${choosenplayers[@]} == "" ]]; then
		echo -e "Choose a Player to add to the game\n"

		gawk -F \: '{print $1 "\t\t" $2 "\t\t" $3}' < ${PATCHIMAGE_DATABASE_DIR}/nsmbw_characters.db

		echo -e "\ntype ???.arc (only one per slot (second column) possible, space separated)"
		read PLAYERS

		for player in ${PLAYERS[@]}; do
			if [[ ! -f "${PATCHIMAGE_DATA_DIR}"/nsmbw_characters/${player} ]]; then
				echo "unkown character ${player}"
				exit 75
			fi
			slot=$(gawk -F \: "/^${player}/"'{print $2}' ${PATCHIMAGE_DATABASE_DIR}/nsmbw_characters.db)
			choosenplayers=( ${choosenplayers[@]} ${player}:${slot} )
		done

		echo ${choosenplayers[@]}
		echo "choosenplayers=( ${choosenplayers[@]} )" > ${HOME}/.patchimage.choice
	fi

	rm -rf workdir

	echo -e "\n*** 3) extracting image"
	${WIT} extract ${IMAGE%/*}/${ID} --psel=data -d workdir -q || exit 51

	for backup in Mario.arc Luigi.arc Kinopio.arc koopa.arc; do
		if [[ ! -f "${PATCHIMAGE_RIIVOLUTION_DIR}/${backup}" ]]; then
			echo "*** 4) first run, backing up original: ${backup}"
			cp workdir/files/Object/${backup} "${PATCHIMAGE_RIIVOLUTION_DIR}"
		else
			echo "*** 4) restoring original: ${backup}"
			cp "${PATCHIMAGE_RIIVOLUTION_DIR}"/${backup} workdir/files/Object/
		fi
	done

	echo "*** 5) replacing characters"
	for player in ${choosenplayers[@]}; do
		cp "${PATCHIMAGE_DATA_DIR}"/nsmbw_characters/${player/:*} \
			workdir/files/Object/${player/*:}
	done

	echo "*** 6) rebuilding game"
	echo "       (storing game in ${PATCHIMAGE_GAME_DIR}/${ID})"
	${WIT} cp -o -q -B workdir ${PATCHIMAGE_GAME_DIR}/${ID} || exit 51

	rm -rf workdir
}