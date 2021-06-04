#!/bin/bash
# this is a build script aimed at making/compiling InfiniTime easier
# Made by ZephyrLabs

# Iniitial test to see if connected to the internet:
wget -q --spider http://github.com
if [ $? -eq 0 ];
then
    echo starting...
else
    dialog --title Information[!] --msgbox "\nPlease connect to the Internet!!" 10 30;
    exit
fi

function main(){
    local input=/tmp/Builder.$$
    local dir=$(pwd)

    cd $dir

    dialog \
        --title "InfiniTime Builder" \
        --menu "What would you like to build today ?" \
        0 0 0 \
        1 "Build InfiniTime" \
        2 "Download Toolchain and Compiler" \
        3 "Apply Modpack"\
        4 "Exit" \
        2>$input

    local selection=$(<"$input")

    if [ $selection == 1 ];
    then
        if [ -d $dir/InfiniTime ];
        then
            if dialog --stdout --title "InfiniTime Build" \
            --yesno "Create build from scratch ?" 7 60; then
                rm -rf InfiniTime
            fi
            InfiniTimeBuild
        fi

    elif [ $selection == 2 ];
    then
        ToolchainSetup
    
    elif [ $selection == 3 ];
    then
        modpackapply        

    elif [ $selection == 4 ];
    then
        dialog --title Information[!] --infobox "\nExiting..." 10 30;sleep 1
        exit
    fi
}

function InfiniTimeBuild(){
    local input=/tmp/Builder.$$
    local dir=$(pwd)

    if [ ! -d $dir/buildtools/gcc-arm-none-eabi ] || [ ! -d $dir/buildtools/nrf5_sdk ];
    then
        dialog --title Information[!] --infobox "\nMissing Compiler or Toolchain!!!" 10 30
    else

        dialog --title Information[!] --infobox "\nGetting Latest source\nplease wait..." 10 30;sleep 1
        git clone https://github.com/JF002/InfiniTime.git --recurse-submodules

        dialog --title Information[!] --infobox "\nSetting up Build environment\nplease wait..." 10 30;sleep 1

        local dir=$(pwd)

        cd InfiniTime
        mkdir build
        cd build

        dialog \
            --title "InfiniTime Build" \
            --menu "What would you like to make ?" \
            0 0 0 \
            1 "DFU package" \
            2 "mcuboot-app" \
            2>$input

            local selection=$(<"$input")

            if [ $selection == 1 ];
            then
                dialog --title Information[!] --infobox "\nSetting up Build environment\nplease wait..." 10 30;sleep 1
                cmake -DARM_NONE_EABI_TOOLCHAIN_PATH=$dir/buildtools/gcc-arm-none-eabi -DNRF5_SDK_PATH=$dir/nrf5_sdk -DNRFJPROG=/opt/nrfjprog/nrfjprog -DBUILD_DFU=1 ../
                make -j8 pinetime-mcuboot-app
            elif [ $selection == 2 ];
            then
                dialog --title Information[!] --infobox "\nSetting up Build environment\nplease wait..." 10 30;sleep 1
                cmake -DARM_NONE_EABI_TOOLCHAIN_PATH=$dir/buildtools/gcc-arm-none-eabi -DNRF5_SDK_PATH=$dir/nrf5_sdk -DUSE-OPENOCD=1 ../
                make -j8 pinetime-mcuboot-app
            fi

            dialog --title Information[!] --msgbox "\nBuild exited\ncheck $dir/Infinitime/build/src/ for Build result" 10 40
    fi 
}

function ToolchainSetup(){

local dir=$(pwd)

if [ -d $dir/buildtools/gcc-arm-none-eabi ] && [ -d $dir/buildtools/nrf5_sdk ];
then 
    dialog --title Information[!] --msgbox "\nCompiler and toolchain are already downloaded" 10 30;sleep 1
    return
fi

mkdir buildtools

dialog --title Information[!] --infobox "\nChecking Architecture" 10 30;sleep 1
arch=$(arch)

if [ $arch == "x86_64" ]; 
then 
dialog --title Information[!] --infobox "\nDownloading for x86_64\nplease wait..." 10 30
curl -s https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2 -o gcc-arm-none-eabi.tar.bz2

elif [ $arch == "aarch64" ];
then
dialog --title Information[!] --infobox "\nDownloading for Aarch64\nplease wait" 10 30
curl -s https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-aarch64-linux.tar.bz2 -o gcc-arm-none-eabi.tar.bz2

else
dialog --title Information[!] --infobox "\ncompatible compiler not found!!!" 10 30;sleep 3
return

fi

dialog --title Information[!] --infobox "\nExtracting\nplease wait..." 10 30
tar -xf gcc-arm-none-eabi.tar.bz2

mv gcc-arm-none-eabi-9-2020-q2-update buildtools/gcc-arm-none-eabi

dialog --title Information[!] --infobox "\nDownloading Toolchain\nplease wait..." 10 30
curl -s https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v15.x.x/nRF5_SDK_15.3.0_59ac345.zip -o nrf5_sdk.zip
unzip -q nrf5_sdk.zip
mv nRF5_SDK_15.3.0_59ac345 buildtools/nrf5_sdk

dialog --title Information[!] --infobox "\nCleaning up..." 10 30
rm -f gcc-arm-none-eabi.tar.bz2
rm -f nrf5_sdk.zip

dialog --title Information[!] --msgbox "\nDone!" 10 30; sleep 3
}

function modpackapply(){
    local dir=$(pwd)

    if [ ! -d $dir/InfiniTime ];
    then
        dialog --title Information[!] --infobox "\nInfiniTime directory doesn't exist!" 10 30;sleep 2
        return
    fi

    FILE=$(dialog --title "Modpack" --stdout --title "Select Modpack" --fselect ${HOME} 14 48)

    if [ -d ${FILE} ] && [ -d ${FILE}/src ];
    then
        cp ${FILE}/src -r $dir/InfiniTime
        dialog --title Information[!] --infobox "\nApplied!" 10 30;sleep 2
        return
    fi

    if [ ${FILE: -11} != 'Modpack.zip' ];
    then
        dialog --title Information[!] --infobox "\nInvalid file type!" 10 30;sleep 2
        return
    fi

    if [ ${FILE: -11} == 'Modpack.zip' ];
    then
        dialog --title Information[!] --infobox "\nApplying ${FILE}\nto InfiniTime..." 10 30;sleep 2

        unzip -q ${FILE} 
        cp $dir/modpack/src -r $dir/InfiniTime
        rm -rf $dir/modpack
        dialog --title Information[!] --infobox "\nApplied!" 10 30;sleep 2
    fi

    if dialog --stdout --title "InfiniTime Build" \
          --yesno "Do you want to build this ?" 7 60; then
            InfiniTimeBuild
    fi

}

while :
do
    main
done