#!/bin/bash

# Формирование списка устанавливаемых модулей
for module in "${!MODULES[@]}"; do
	if [[ ${MODULES[$module]} != true ]]; then
		continue
	fi
	checkdeps $module true
done

# Вывод результирующего списка установки
echo "========= INSTALLATION LIST =========="

for module in "${ORDERED_MODULES[@]}"; do
	[[ ${MODULES[$module]} ]] && {
		echo $module = ${MODULES[$module]}
	}
done

echo "======================================"

confirm "Install these modules? (y/[a]): "

# Установка
echo "============ INSTALLATION ============"

for module in "${ORDERED_MODULES[@]}"; do

	if [ ${MODULES[$module]} != true ]; then
		continue
	fi

	echo " ‒ Installing module $module..."

	INSTALL_FILE="$MODULES_FOLDER/$module/install.sh"
	checkFile $INSTALL_FILE

	. $INSTALL_FILE

done