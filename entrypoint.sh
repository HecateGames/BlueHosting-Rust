#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
export INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')

# Steam update: только при явном AUTO_UPDATE=1 (для devblog оставляем выкл по умолчанию)
if [[ "${AUTO_UPDATE}" == "0" ]]; then
 ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 258550 +quit
else
 echo "Steam update disabled (AUTO_UPDATE!=1). Using existing game files."
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Carbon — обновляем только если ещё не установлен
if [[ "${FRAMEWORK}" == "carbon" ]]; then
 if [[ ! -d "carbon/managed" ]]; then
  echo "Installing Carbon..."
  curl -sSL "https://github.com/CarbonCommunity/Carbon.Core/releases/download/production_build/Carbon.Linux.Release.tar.gz" | tar zx
  echo "Done!"
 fi
 export DOORSTOP_ENABLED=1
 export DOORSTOP_TARGET_ASSEMBLY="$(pwd)/carbon/managed/Carbon.Preloader.dll"
 MODIFIED_STARTUP="LD_PRELOAD=$(pwd)/libdoorstop.so ${MODIFIED_STARTUP}"

elif [[ "$OXIDE" == "1" ]] || [[ "${FRAMEWORK}" == "oxide" ]]; then
 if [[ ! -f "RustDedicated_Data/Managed/Oxide.Core.dll" ]]; then
  echo "Installing Oxide..."
  curl -sSL "https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip" -o umod.zip
  unzip -o -q umod.zip && rm umod.zip
  echo "Done!"
 fi
fi

# Fix for Rust not starting
export LD_LIBRARY_PATH=$(pwd)/RustDedicated_Data/Plugins/x86_64:$(pwd)

# Максимум ресурсов для быстрого запуска
ulimit -n 65535 2>/dev/null || true
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-$(nproc 2>/dev/null || echo 8)}
export UV_THREADPOOL_SIZE=${UV_THREADPOOL_SIZE:-16}
export MALLOC_ARENA_MAX=2

# Повышенный приоритет CPU и I/O для быстрой загрузки (если разрешено)
if nice -n -5 true 2>/dev/null; then
  exec nice -n -5 ionice -c 1 -n 0 node /wrapper.js "${MODIFIED_STARTUP}"
else
  exec node /wrapper.js "${MODIFIED_STARTUP}"
fi

