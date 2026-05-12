#!/bin/bash

# x86-64-v2优化
sed -i 's/O2/O2 -march=x86-64-v2/g' include/target.mk

# libsodium
sed -i 's,no-mips16 no-lto,no-mips16,g' feeds/packages/libs/libsodium/Makefile

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/rc.local <<'EOF'
#!/bin/sh

if grep "Default string" /tmp/sysinfo/model > /dev/null 2>&1; then
    echo "Generic PC" > /tmp/sysinfo/model
fi

if [ -f /sys/devices/system/cpu/intel_pstate/status ]; then
    status=$(cat /sys/devices/system/cpu/intel_pstate/status)

    if [ "$status" = "passive" ]; then
        echo "active" > /sys/devices/system/cpu/intel_pstate/status
    fi
fi

exit 0
EOF

chmod +x package/base-files/files/etc/rc.local

# Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/tags | \
grep -Eo 'v[0-9\.]+\-*r*c*[0-9]*.tar.gz' | \
sed -n '/[2-9][5-9]/p' | \
head -n 1 | \
sed 's/v//g' | \
sed 's/.tar.gz//g')"

wget -q https://downloads.openwrt.org/releases/${latest_version}/targets/x86/64/profiles.json

if [ -f profiles.json ]; then
    jq -r '.linux_kernel.vermagic' profiles.json > .vermagic

    sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
fi

# 预配置
cp -rf ../PATCH/files ./files 2>/dev/null

# 清理
find ./ -name "*.orig" -delete
find ./ -name "*.rej" -delete

# 默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

exit 0
