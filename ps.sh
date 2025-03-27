#!/usr/bin/env bash
# ps.sh - Personaliza o prompt do Termux Android
# 
# Autor: Oliver, 2025
#
# Autor			: Oliver Silva, <oliveobom100@gmail.com>
# Manutenção	: Oliver Silva, <oliveobom100@gmail.com>
#
# -------------------------
# Este programa personaliza o prompt do Termux Android, melhora visualmente o terminal.
#
# Exemplo:
#
# ./ps.sh --setup-conf parrot
# 
# + Fazendo backup...OK
# + Configurando...OK
#
# Histórico:
#
# v0.1 2025-03-27, Oliver Silva:
#	Adicionado suporte para listagem de distros, estilos de prompt de uma distro, aplicar uma configuração, desfazer uma configuração, fazer e restaurar backup, modificar o nome de usuário e host.
#
# Licença: License MIT
# 
# Versão 0.1: Listagem de distros e estilos de prompt, fazer e desfazer uma configuração, backup, alterar nome usenrname e hostname

source distros.sh


config_file=$HOME/.bash_login
sd="  "

# CTRL + C
function trap_alert() {
	echo -e '\n\e[1;31m! Cancelado\e[0m'
	exit 1
}

# LISTA DISTROS
function list_distros() {
	for distro in "${!distros[@]}"; do
		json="${distros["$distro"]}"

		name=$(echo "$json" | jq -r '.name')
	
		echo -e "\e[2;32m√ \e[0m$name \e[1;31m-> \e[0m$distro"
	done
}

# LISTA ESTILOS DE PROMPT
function list_prompt_style() {
	local distro_arg=$1

	if [[ -n "${distros["$distro_arg"]}" ]]; then
		json="${distros["$distro_arg"]}"

		echo "$json" | jq -c '.prompt_style | to_entries[]' | while read -r entry; do
			key=$(echo "$entry" | jq -r '.key')
			prompt_name=$(echo "$entry" | jq -r '.value.name')
			echo -e "\e[2;32m√ \e[0m$prompt_name \e[1;31m-> \e[0m$key"
		done
	else
		echo -e "\e[1;31m! \e[0mNenhum estilo para a distro $distro_arg"
		exit 1
	fi
}

# Configura
function setup_conf() {
	local distro_arg=$1

	trap trap_alert SIGINT

	[[ ! -f $config_file ]] && >$config_file

	if [[ -n "${distros["$distro_arg"]}" ]]; then

		if grep -q "^distro_name=" $config_file; then
			echo -e "\e[1;31m! \e[0mUm dos nossos arquivos encontrado, tem certeza que quer substituir? ENTER para confirmar ou CTRL+C para interromper..."; read
		fi
	
		do_backup
		
		printf "\r* Configurando..."
		cat ./config/${distro_arg} >> $config_file
		printf "\r+ Configurando...OK\n"
	else
		echo -e "\e[1;31m! \e[0mDistro $distro_arg inexistente...Failed\n"
		exit 1
	fi
}

# Desfaz a configuração
function undo_conf() {
	if [[ -f "$config_file" ]]; then
		printf "\r* Desfazendo configuração..."
		rm $config_file
		printf "\r+ Desfazendo configuração...OK\n"
	else
		printf "\r! Nenhuma configuração...Failed\n"
		exit 1
	fi
}

# Backup do arquivo atual
function do_backup() {
	if [[ -f $config_file ]]; then
		printf "\r* Fazendo backup..."
		[ ! -d ./.backup ] && mkdir .backup
		cp $config_file ./.backup/"backup_$(date '+%H:%M:%S_%d-%m-%Y')"
		printf "\r+ Fazendo backup...OK\n"
	else
		printf "\r! Nenhum arquivo para o backup...Failed\n"
	fi
}

# Restaurar o ultimo backup
function do_restory() {
	latest_backup=$(ls -t .backup | head -n 1)

	if [[ -n "$latest_backup" ]]; then
		printf "\r* Restaurando backup $latest_backup..."
		cat ./.backup/$latest_backup > $config_file
		printf "\r+ Restaurando backup $latest_backup...OK\n"
	else
		printf "\r! Restaurando backup...Failed\n"
	fi
}

# Modificar o ps
function modify_ps() {
	local ps_arg=$1
	local distro_author="olliv3r"

	if [[ -f $config_file ]]; then

		if ! grep -q "^distro_author=" $config_file; then
			echo -e "\e[1;31m! \e[0mA chave distro_author não foi encontrada no arquivo!"
			exit 1
		fi

		# Verifica se o arquivo de conf é um dos nossos
		file_distro_author=$(grep -oP 'distro_author="\K[^"]+' $config_file | head -n 1)
		
		if [[ "$distro_author" == "$file_distro_author" ]]; then
			if ! grep -q "^prompt_type=" $config_file; then
				echo -e "\e[1;31m! \e[0mA chave prompt_type não foi encontrada no arquivo!"
				exit 1
			fi
			
			sed -i "s/prompt_type=\".*\"/prompt_type=\"$ps_arg\"/" $config_file
			echo -e "\e[2;32m+ \e[0mPrompt de estilo alterado para $ps_arg"

		else
			echo "Este arquivo não é de uma de nossas distros. Configure uma das nossas!"
			exit 1
		fi
		
	else
		echo "Arquivo de configuração não encontrado. Configure uma distro para poder modificar o estilo de prompt!"
		exit 1
	fi
}

# Modifica o username
function modify_user() {
	local user_arg=$1
	distro_author="olliv3r"

	if [[ ! -f $config_file ]]; then
		echo -e "! Nenhuma configuração...Failed\n"
		exit 1
	fi

	if grep -q "^distro_author=" $config_file; then
		file_distro_author=$(grep -oP 'distro_author="\K[^"]+' $config_file | head -n 1)

		if [[ "$distro_author" == "$file_distro_author" ]]; then
		
			if grep -q "^user_name=" $config_file; then
				sed -i "s/user_name=\".*\"/user_name=\"$user_arg\"/" $config_file
				echo -e "\n+ Usuário alterado!\n"
			else
				echo -e "\e[1;31m! \e[0mA chave user_name não foi encontrada no arquivo!"
				exit 1
			fi
			
		else
			echo "Este arquivo não é de uma de nossas distros. Configure uma das nossas!"
			exit 1
		fi
		
	else
		echo -e "\e[1;31m! \e[0mA chave distro_author não foi encontrada no arquivo!"
		exit 1
	fi
}

# Modifica o host
function modify_host() {
	local host_arg=$1
	distro_author="olliv3r"

	if [[ ! -f $config_file ]]; then
		echo -e "! Nenhuma configuração...Failed\n"
		exit 1
	fi

	if grep -q "^distro_author=" $config_file; then
		file_distro_author=$(grep -oP 'distro_author="\K[^"]+' $config_file | head -n 1)

		if [[ "$distro_author" == "$file_distro_author" ]]; then
		
			if grep -q "^host_name=" $config_file; then
				sed -i "s/host_name=\".*\"/host_name=\"$host_arg\"/" $config_file
				echo -e "\n+ Host alterado!\n"
			else
				echo -e "\e[1;31m! \e[0mA chave host_name não foi encontrada no arquivo!"
				exit 1
			fi
			
		else
			echo "Este arquivo não é de uma de nossas distros. Configure uma das nossas!"
			exit 1
		fi
		
	else
		echo -e "\e[1;31m! \e[0mA chave distro_author não foi encontrada no arquivo!"
		exit 1
	fi
}


function usage_help() {
	echo -e "Programa que personaliza o prompt do Termux Android.\n\nUsage: $(basename "$0") [OPTIONS] ... [ARGUMENTS]\n\n$sd-hh, --help\tMostra esta tela de ajuda e sai\n$sd-ld, --list-distros\n\t\tLista distros disponíveis para uso\n$sd-lps <DISTRO>, --list-ps <DISTRO>\n\t\tLista todos os estilos de prompt de uma distro\n$sd-sc <DISTRO>, --setup-conf <DISTRO>\n\t\tAplica a configuração de uma distro\n$sd-uc, --undo-conf\n\t\tDesfaz a configuração atual de uma distro\n$sd-ps <PROMPT_STYLE>, --prompt-style <PROMPT_STYLE>\n\t\tModifica o estilo do prompt de uma distro\n$sd-u <NEW_USER>, --user <NEW_USER>\n\t\tModifica o nome de usuário\n$sd-h <NEW_HOST>, --host <NEW_HOST>\n\t\tModifica o nome do host\n$sd--restory\tRestaura o ultimo backup"
}

# TRATAMENTO DAS OPÇÔES
if [ -n "$1" ]; then

	while [ -n "$1" ]; do

		case "$1" in
			-hh| --help) usage_help;;
			-ld | --list-distros)
				list_distros;;
			-lps| --list-ps)
				shift

				distro_arg=$1

				if [ -z "$distro_arg" ]; then
					echo 'Precisa da distro!'
					exit 1
				fi
				
				list_prompt_style $distro_arg;;
			-sc| --setup-conf)
				shift

				distro_arg=$1

				if [ -z "$distro_arg" ]; then
					echo "Precisa da distro!"
					exit 1
				fi

				setup_conf $distro_arg;;
			-uc| --undo-conf)
				undo_conf;;
			-ps| --prompt-style)
				shift

				ps_arg=$1

				if [[ -z "$ps_arg" ]]; then
					echo "Precisa de um estilo de prompt!"
					exit 1
				fi

				modify_ps $ps_arg;;
			-u| --user)
				shift

				user_arg=$1

				if [[ -z "$user_arg" ]]; then
					echo "Precisa de um usuário!"
					exit 1
				fi

				modify_user $user_arg;;
			-h| --host)
				shift

				host_arg=$1

				if [[ -z "$host_arg" ]]; then
					echo "Precisa de um host!"
					exit 1
				fi

				modify_host $host_arg;;
			--restory)
				do_restory;;
			*)
				usage_help;;
		esac
		
		shift
	done
else
	usage_help
fi
