#!/usr/bin/env bash
# Arquivos de configuraçôes
# Por oliver, 2023
#

### VARIÁVEIS ###

usage_key=0
list_key=0
list_prompt_style_key=0
setup_config_key=0
prompt_style_key=0
undo_key=0

list_prompt_style_kali=(
  "backtrack" 
  "oneline" 
  "twoline"
)

### FUNÇÔES ###

usage() {
  echo -e "Usage: $(basename "$0") [OPÇÔES]\n
  -h, --help\tMostra esta tela de ajuda e sai
  -l, --list\tLista configuraçôes de distros
  -lps distro\tLista os estilos de prompts de uma distro
  -s distro, --setup distro\n\t\tAplica a configuração de uma distro
  -ps prompt_style\n\t\tAplica o estilo do prompt de uma distro
  -u, --undo\tDesfazer a configuração
  "
}

list_config() {
  if [ -d ./config ] ; then
    echo -e "Distros:\n"
    index=1
    for config in ./config/* ; do
      echo "[$index] $(basename "${config@u}")"
      index=$((index +1))
    done

  else
    echo "Nenhuma distro encontrada!";
  fi
}

list_prompt_style() {
  case "$distro_arg_ps" in
    kali) show_prompt_style;;
    *)
      echo "Nenhum estilo para essa distro!";;
  esac
}

show_prompt_style() {
  echo -e "Todos os estilos do ${distro_arg_ps}\n"
  index=1
  for ps_style in ${list_prompt_style_kali[*]} ; do
    echo "[${index}] ${ps_style@u}"
    index=$((index +1))
  done
}

setup_config() {
  case "$config_arg" in
    kali)
      case "$prompt_style_arg" in
	backtrack) setup;;
	oneline) setup;;
	twoline) setup;;
	"") setup;;
        *)
          echo "Estilo de prompt inválido"
	  exit 1;;
        esac
      ;;
    parrot) setup;;
    *)
      echo "Distro inválida"
      exit 1;;
  esac
}

setup() {
  do_backup
  printf "\r[*] Configurando $config_arg..."
  echo "export prompt_type=$prompt_style_arg" > $HOME/.bash_login
  cat ./config/$config_arg >> $HOME/.bash_login
  printf "\r[+] Configurando $config_arg...OK\n"
  exit 0
}

do_backup() {
  if [ -f $HOME/.bash_login ] ; then
    printf "\r[*] Fazendo backup..."
    [ ! -d ./backup ] && mkdir ./backup
    cat $HOME/.bash_login > backup/.bash_login
    printf "\r[+] Fazendo backup...OK\n"
  fi
}

restory_backup() {
  if [ -d ./backup -a -f ./backup/bash_login ] ; then
    printf "\r[*] Restaurando backup..."
    cat ./backup/bash_login > $HOME/.bash_login
    printf "\r[+] Restaurando backup...OK\n"
  fi
}

undo() {
  if [ -f $HOME/.bash_login ] ; then
    printf "\r[*] Desfazendo config..."
    rm $HOME/.bash_login
    printf "\r[+] Desfazendo config...OK\n"
    restory_backup
  else
    echo "[!] Nenhuma configuração encontrada"
    exit 1
  fi
}

### VERIFICAÇÃO ###

if [ ${#@} -eq 0 ] ; then
  echo "::: Banner :::"
  exit 0
else
  while [ -n "$1" ] ; do
    case "$1" in
      -h|--help) usage_key=1;;
      -l|--list) list_key=1;;
      -lps) 
	shift
	if [ -z "$1" ] ; then
	  echo "Requer uma distro!"
	  exit 1
	fi
	distro_arg_ps="$1"
	list_prompt_style_key=1
	;;
      -s|--setup)
	shift
	if [ -z "$1" ] ; then
	  echo "Requer uma distro!"
	  exit 1
	fi
	config_arg="$1"
	setup_config_key=1
	;;
      -ps)
	shift
	if [ -z "$1" ] ; then
	  echo "Requer um estilo de prompt!"
	  exit 1
	fi
	prompt_style_arg="$1"
	prompt_style_key=1
	;;
      -u|--undo) undo_key=1;;
      *)
        echo "Opção inválida!" && exit 1
    esac
    shift
  done
fi

### EXECUÇÃO ###

if [ $usage_key -eq 1 ] ; then
  usage && exit 0
elif [ $list_key -eq 1 ] ; then
  list_config && exit 0
elif [ $list_prompt_style_key -eq 1 ] ; then
  list_prompt_style
elif [ $setup_config_key -eq 1 -a $prompt_style_key -eq 0 ] ; then
  setup_config && exit 0
elif [ $setup_config_key -eq 1 -a $prompt_style_key -eq 1 ] ; then
  setup_config && exit 0
elif [ $undo_key -eq 1 ] ; then
  undo && exit 0
else
  echo "Comando não pode ser processado!"
  echo "Tente -h,--help para mais informaçôes"
  exit 1
fi
