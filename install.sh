#初始化一些常用的tput格式
set_color_env()
{
    OK="$(tput setaf 2)[OK]$(tput sgr0)"
    ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
    NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
    WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
    CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
    RESET=$(tput sgr0)

    RED=$(tput setaf 1)
    GREN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    LIGHTBLUE=$(tput setaf 6)
    ORANGE=$(tput setaf 166)
    WIGHT=$(tput setaf 255)
}

set_basic_env(){
  set_color_env
  LOG="install-$(date +d-%H%M%S).log"
  TERM_WIDTH=$(tput cols)
}

#在屏幕中间打印文本
#输入为 $1=文本 $2=tput格式
#eg. print_text_middle "helloworld" "${GREN}"
print_text_middle() {
    local text="$1"            # 要输出的文本
    local cols=$(tput cols)    # 获取终端的列数
    local text_length=${#text} # 获取文本长度

    # 计算要在行中间输出的起始位置
    local start_position=$(( (cols - text_length) / 2 ))

    # 设置终端颜色
    local color_code="$2"  # 文本颜色代码
    local color_reset=$(tput sgr0)  # 重置颜色

    # 使用printf打印空格和带有颜色的文本
    printf "%*s%s%s%s\n" $((start_position)) "" "$color_code" "$text" "$color_reset"
}

#在屏幕中间打印文本，但是覆盖式
#输入为 $1=文本 $2=tput格式
#eg. print_text_middle "helloworld" "${GREN}"
print_text_middle_recover() {
    local text="$1"            # 要输出的文本
    local cols=$(tput cols)    # 获取终端的列数
    local text_length=${#text} # 获取文本长度
    local start_position=$(( (cols - text_length) / 2 ))
    local color_code="$2"  # 文本颜色代码
    local color_reset=$(tput sgr0)  # 重置颜色
    printf "%*s%s%s%s\r" $((start_position)) "" "$color_code" "$text" "$color_reset"
}

#在屏幕中间打印读秒
#输入为 $1=秒数
#eg. countdown 5
countdown() {
    local seconds=$1

    while [ $seconds -gt 0 ]; do
	print_text_middle_recover $seconds "${WIGHT}"
	#printf "\rCountdown: %2d" $seconds
        sleep 1  # 等待1秒
        ((seconds--))
    done
    print_text_middle_recover "Start" "${LIGHTBLUE}"
    printf "\n"
}

# 提示用户输入y或n
prompt_yes_no() {
    local prompt="$1"
    prompt+=" (y/n) "
    # 循环等待用户输入
    while true; do
        read -p "$prompt" yn
        yn="${yn:-$default}"  # 如果用户直接按下回车，则使用默认值
        # 将用户输入转换为小写字母并检查有效性
        case $yn in
            [Yy]*)
                return 0
                ;;
            [Nn]*)
                return 1
                ;;
            *)
              printf "${ERROR}不合法的输入\n"
            ;;
        esac
    done
}

insert_text_if_not_exist() {
    local file_path="$1"
    local text="$2"

    if ! grep -qF "$text" "$file_path"; then
        echo "$text" >> "$file_path"
    fi
}

ensure_aur(){
  ISAUR=$(command -v yay || command -v paru)
  
  if [ -n "$ISAUR" ]; then
    printf "\n%s - AUR helper was located, moving on.\n" "${OK}"
  else
    printf "\n%s - AUR helper was NOT located\n" "$WARN"

  while true; do
    read -rp "${CAT} Which AUR helper do you want to use, yay or paru? Enter 'y' or 'p': " choice
    case "$choice" in 
      y|Y)
      printf "\n%s - Installing yay from AUR\n" "${NOTE}"
      git clone https://aur.archlinux.org/yay-bin.git || { printf "%s - Failed to clone yay from AUR\n" "${ERROR}"; exit 1; }
      cd yay-bin || { printf "%s - Failed to enter yay-bin directory\n" "${ERROR}"; exit 1; }
      makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Failed to install yay from AUR\n" "${ERROR}"; exit 1; }
      cd ..
      break
    ;;
      p|P)
      printf "\n%s - Installing paru from AUR\n" "${NOTE}"
      git clone https://aur.archlinux.org/paru-bin.git || { printf "%s - Failed to clone paru from AUR\n" "${ERROR}"; exit 1; }
      cd paru-bin || { printf "%s - Failed to enter paru-bin directory\n" "${ERROR}"; exit 1; }
      makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Failed to install paru from AUR\n" "${ERROR}"; exit 1; }
      cd ..
      break
    ;;
    *)
    printf "%s - Invalid choice. Please enter 'y' or 'p'\n" "${ERROR}"
    continue
    ;;
    esac
  done
fi
}

#使用aur安装软件
#$1=软件名
#eg. aur_install_package qqmusion-bin
aur_install_package() {
    ISAUR=$(command -v yay || command -v paru)
    if $ISAUR -Q "$1" &>> /dev/null ; then
      print_already_install $1
    else
      # package not installed
      echo -e "${NOTE} installing $1 ..."
      $ISAUR -S --noconfirm "$1" 2>&1 | tee -a "$LOG"
      # making sure package installed
      if $ISAUR -Q "$1" &>> /dev/null ; then
        print_install_succeed $1
      else
        # something is missing, exitting to review log
        print_install_failed $1
        exit 1
      fi
    fi
}

#使用pacman安装软件
#$1=软件名
#eg. pacman_install_package qqmusion-bin
pacman_install_package() {
    PACMAN=$(command -v pacman)
    # checking if package is already installed
    if $PACMAN -Q "$1" &>> /dev/null ; then
      print_already_install $1
    else
      echo -e "${NOTE} installing $1 ..."
      $PACMAN -S --noconfirm "$1" 2>&1 | tee -a "$LOG"
      # making sure package installed
      if $PACMAN -Q "$1" &>> /dev/null ; then
        print_install_succeed $1
      else
        # something is missing, exitting to review log
        print_install_failed $1
        exit 1
      fi
    fi
}

print_install_succeed(){
  echo -e "\e[1A\e[K${OK} $1 安装成功." | tee -a "$LOG"
}

print_install_failed(){
  echo -e "\n\e[1A\e[K${ERROR} $1 failed to install :( , please check the install.log . You may need to install manually! Sorry I have tried :(\n" | tee -a "$LOG"
}

print_already_install(){
  echo -e "${OK} $1 已安装. 跳过..."
}

# Function to print error messages
print_error() {
    printf " %s%s\n" "${ERROR}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}

# Function to print success messages
print_success() {
    printf "%s%s%s\n" "${OK}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}


check_base_env(){
  printf "\n${NOTE} 检查网络连接\n"
  ping -c3 www.baidu.com
  if [ $? -ne 0 ]; then
    print_error "网络不通"
  fi
  printf "\n${NOTE} 检查命令pacman\n"
  command -v pacman > /dev/null 2>&1
  if [ $? -ne 0 ];then
    print_error "pacman命令找不到"
  fi
}

install_base(){
  for PKG1 in vim git wget curl sudo gcc; do
    pacman_install_package "$PKG1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
      echo -e "\e[1A\e[K${ERROR} - $PKG1 install had failed, please check the install.log"
      exit 1
    fi
  done
}

install_golang(){
  if [[ $(command -v go) ]]; then
    print_already_install "golang"
  else
    url="https://golang.google.cn/dl/"
    web_content=$(curl -s "$url")
    versions=$(echo "$web_content" | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | awk '!seen[$0]++' | head -n 40) 
    echo "可安装的Go版本列表："
    PS3="请选择1-40: "
    select opt in ${versions[@]}; do
      echo $REPLY
      if [[ $REPLY =~ ^[0-9]+$ ]] && [[ $REPLY -gt 0 && $REPLY -lt 41 ]]; then
        printf "您将安装${opt:2}版本的Golang程序"
        wget https://dl.google.com/go/go${opt:2}.linux-amd64.tar.gz
        if [[ $? -ne 0 ]]; then
          echo -e "\e[1A\e[K${ERROR} - Golang install had failed, please check the install.log"
          exit 1
        fi
        sudo tar -xzvf go${opt:2}.linux-amd64.tar.gz  -C /usr/local/lib
        insert_text_if_not_exist "$HOME/.bashrc" "export GOROOT=/usr/local/lib/go"
        insert_text_if_not_exist "$HOME/.bashrc" "export GOPATH=/home/${USER}/sdk/go"
        insert_text_if_not_exist "$HOME/.bashrc" "export PATH=$GOROOT/bin:$GOPATH/bin:$PATH"
        insert_text_if_not_exist "$HOME/.bashrc" "export GOPROXY=https://goproxy.io,direct" 
        source $HOME/.bashrc
        if [[ $(go version) ]]; then
          print_install_succeed ${opt}
        else
          print_install_failed ${opt}
        fi
        rm -f go${opt:2}.linux-amd64.tar.gz
        break
      else
        echo "输入了无效的数字"
      fi
    done
  fi
}

install_rust(){
  if [[ $(command -v cargo) ]]; then
    print_already_install "rust"
  else
    curl https://sh.rustup.rs -sSf | sh
    source "$HOME/.cargo/env"
    if [[ $(cargo --version) ]]; then
      print_install_succeed $(cargo --version)
    else
      print_install_failed "rust"
    fi
  fi
}

set_basic_env
install_base
install_rust
exit 0
######################开始执行脚本#########################

#clear screen
clear

set_color_env


print_text_middle "Welcome to My Arch Linux Hyprland Installer" ${LIGHTBLUE}
print_text_middle "Github: https://github.com/Wangyiwei-So/archlinux-installer" ${LIGHTBLUE}

sleep 1

printf "\n"
printf "\n"
print_text_middle "Please Backup Your Files" "${ORANGE}$(tput smso)"

sleep 1

printf "\n"
printf "\n"
print_text_middle "Please Ensure You Have Set Nessasary Settings and I will Do Some Check" "${ORANGE}$(tput smso)"
print_text_middle "" "${ORANGE}$(tput smso)"
print_text_middle "Please Ensure You Have Set Nessasary Settings" "${ORANGE}$(tput smso)"
sleep 4
printf "\n"
printf "\n"
print_text_middle "Some commands require you to enter your password in order to execute" "${ORANGE}"

printf "\n"
printf "\n"

## 确认安装
if prompt_yes_no "${CAT} Can we proceed with installation" ; then
  printf "\n%s  Alright.....LETS BEGIN!.\n" "${OK}"
else
  printf "\n%s  NO changes made to your system. Goodbye.!!!\n" "${NOTE}"
  exit
fi

sleep 1


## 安装AUR
printf "\n${ACTION} - 安装AUR"
ensure_aur

## 更新源
update_pacman_source() {
  if prompt_yes_no "${ACTION} - 更新源 将默认使用清华源"; then
    local msg="Server = http:\/\/mirrors.tuna.tsinghua.edu.cn\/archlinux\/\$repo\/os\/\$arch"
    local mirrfile="/etc/pacman.d/mirrorlist"
    local first_line=$(head -n 1 "$mirrfile")
    if [ "$first_line" == "$msg" ]; then
      return 0
    else
      sudo sed -i "1s/^/$msg\n/" "$mirrfile"
      pacman -Syu
    fi
  else
    printf "\n%s  NO changes made to your system. Goodbye.!!!\n" "${NOTE}"
    exit
  fi
}
update_pacman_source

ISAUR=$(command -v yay || command -v paru)
$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Failed to update system\n" "${ERROR}"; exit 1; }

set -e

##
printf "\n${ACTION} - 安装Hyprland"
sleep 2
# Hyprland Main installation part including automatic detection of Nvidia-GPU is present in your system
if ! lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    printf "${YELLOW} No NVIDIA GPU detected in your system. Installing Hyprland without Nvidia support..."
    sleep 1
    for HYP in hyprland; do
        aur_install_package "$HYP" 2>&1 | tee -a $LOG
    done
else
	# Prompt user for Nvidia installation
	printf "${YELLOW} NVIDIA GPU Detected. Kindly note that Nvidia-Wayland is still kinda wonky. Kindly check Hyprland Wiki if Issues encountered!\n"
	sleep 1
	printf "${YELLOW} Kindly enable some Nvidia-related stuff in the configs after installation\n"
	sleep 2
	read -n1 -rp "Would you like to install Nvidia Hyprland? (y/n) " NVIDIA
	echo

	if [[ $NVIDIA =~ ^[Yy]$ ]]; then
    	# Install Nvidia Hyprland
    	printf "\n"
    	printf "${YELLOW}Installing Nvidia Hyprland...${RESET}\n"
    	if pacman -Qs hyprland > /dev/null; then
        	read -n1 -rp "Hyprland detected. Would you like to remove and install hyprland-nvidia instead? (y/n) " nvidia_hypr
        	echo
        	if [[ $nvidia_hypr =~ ^[Yy]$ ]]; then
            	sudo pacman -R --noconfirm hyprland 2>/dev/null | tee -a "$LOG" || true
        	fi
    		fi
    		for hyprnvi in hyprland hyprland-nvidia hyprland-nvidia-hidpi-git; do
        	sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
    		done
    	aur_install_package "hyprland-nvidia-git" 2>&1 | tee -a $LOG
	else
    		printf "\n"
   	 	printf "${YELLOW} Installing non-Nvidia Hyprland...\n"
    		for hyprnvi in hyprland-nvidia-git hyprland-nvidia hyprland-nvidia-hidpi-git; do
        	sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
    		done
    		for HYP2 in hyprland; do
        aur_install_package "$HYP2" 2>&1 | tee -a $LOG
    		done
	fi

    # Install additional nvidia packages
    printf "${YELLOW} Installing additional Nvidia packages...\n"
        for krnl in $(cat /usr/lib/modules/*/pkgbase); do
            for NVIDIA in "${krnl}-headers" nvidia-dkms nvidia-settings nvidia-utils libva libva-nvidia-driver-git; do
            aur_install_package "$NVIDIA" 2>&1 | tee -a $LOG
            done
        done

    # adding nvidia modules in mkinitcpio
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a $LOG
        sudo mkinitcpio -P 2>&1 | tee -a $LOG
    printf "\n"
    printf "\n"

    # preparing exec.conf to enable env = WLR_NO_HARDWARE_CURSORS,1 so it will be ready once config files copied
    sed -i '44s/#//' config/hypr/configs/exec.conf

    # Additional Nvidia steps
    NVEA="/etc/modprobe.d/nvidia.conf"
    if [ -f "$NVEA" ]; then
            printf "${OK} Seems like nvidia-drm modeset=1 is already added in your system..moving on.\n"
            printf "\n"
        else
            printf "\n"
            printf "${YELLOW} Adding options to $NVEA..."
            sudo echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a $LOG
            printf "\n"
            fi

	# Blacklist nouveau
	read -n1 -rep "${CAT} Would you like to blacklist nouveau? (y/n)" response
	echo
	if [[ $response =~ ^[Yy]$ ]]; then
    	NOUVEAU="/etc/modprobe.d/nouveau.conf"
    	if [ -f "$NOUVEAU" ]; then
        	printf "${OK} Seems like nouveau is already blacklisted..moving on.\n"
    	else
        	printf "\n"
        	echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | tee -a $LOG
        	printf "${NOTE} has been added to $NOUVEAU.\n"
        	printf "\n"

        	# to completely blacklist nouveau (See wiki.archlinux.org/title/Kernel_module#Blacklisting 6.1)
        	if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
            	echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG
        	else
            	echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG
        	fi
    	fi
	else
    	printf "${NOTE} Skipping nouveau blacklisting.\n"
	fi

fi

#clear screen
clear

### 安装依赖包
printf "\n${ACTION} 安装依赖包"
sleep 2
for PKG1 in foot swaybg swaylock-effects wofi wlogout mako grim slurp wl-clipboard polkit-kde-agent nwg-look-bin swww pavucontrol playerctl; do
   aur_install_package "$PKG1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $PKG1 install had failed, please check the install.log"
        exit 1
    fi
done


for PKG2 in qt5ct btop jq xsel gvfs gvfs-mtp ffmpegthumbs mpv curl pamixer brightnessctl xdg-user-dirs ristretto swappy mpv network-manager-applet cava gtk4 unzip; do
    aur_install_package  "$PKG2" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $PKG2 install had failed, please check the install.log"
        exit 1
    fi
done

###关于声音的软件安装
for SAPP1 in alsa-utils alsa-firmware sof-firmware alsa-ucm-conf; do
    pacman_install_package  "$SAPP1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
      print_install_failed $SAPP1
      exit 1
    fi
done

for SAPP2 in mate-media pulseaudio; do
    aur_install_package  "$SAPP1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
      print_install_failed $SAPP1
      exit 1
    fi
done

pulseaudio --start

insert_text_if_not_exist "~/.bashrc" "pulseaudio --start"

###安装字体
printf "\n${ACTION} 安装字体"
sleep 2
for FONT in ttf-jetbrains-mono-nerd nerd-fonts-sarasa-term; do
    aur_install_package  "$FONT" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $FONT install had failed, please check the install.log"
        exit 1
    fi
done

### 安装waybar
printf "\n${ACTION} 安装waybar"
sleep 2
for PKG3 in meson ninja spdlog-git fmt9 fmt; do
    install_package  "$PKG3" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $FONT install had failed, please check the install.log"
        exit 1
    fi
done
git clone https://github.com/Alexays/Waybar
cd Waybar
git checkout 0.9.17
meson build
ninja -C build
ninja -C build install



###安装应用软件
printf "\n${ACTION} 安装应用软件"
sleep 2
for APP1 in openssh visual-studio-code-bin ; do
    install_package  "$APP1" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $FONT install had failed, please check the install.log"
        exit 1
    fi
done

printf "\n${ACTION} 安装chrome"
sleep 2
git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
makepkg -si 2>&1 | tee -a "$LOG"
if [ $? -ne 0 ]; then
  echo -e "\e[1A\e[K${ERROR} - $FONT install had failed, please check the install.log"
  exit 1
fi
cd -

### 可选：安装golang
printf "\n${ACTION} 安装Golang"
sleep 2
if prompt_yes_no "要安装golang吗?"; then
  install_golang
else
  printf "\n${OK}跳过golang安装"
fi

printf "\n${ACTION} 安装docker"
sleep 2

printf "\n${ACTION} 安装nvim"
sleep 2
pacman_install_package neovim

