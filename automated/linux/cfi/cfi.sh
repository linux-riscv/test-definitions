#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib

OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
RESULT_LOG="${OUTPUT}/result_log.txt"
CWD=""

cfi_run_test() {
    # shellcheck disable=SC2164
    # Redirect stdout (not stderr)
    cd /opt/cfi/

    echo -n "cfi_compiled_should_succeed " > "${RESULT_FILE}"
    ./cfi_compiled_should_succeed | tee -a "${RESULT_LOG}"
    if [[ "${PIPESTATUS[0]}" == "0" ]]; then
        echo "pass" >> "${RESULT_FILE}"
    else
        echo "fail" >> "${RESULT_FILE}"
    fi

    echo -n "not_cfi_compiled_should_fail " >> "${RESULT_FILE}"
    ./not_cfi_compiled_should_fail | tee -a "${RESULT_LOG}"
    if [[ "${PIPESTATUS[0]}" == "139" ]]; then
        echo "pass" >> "${RESULT_FILE}"
    else
        echo "fail" >> "${RESULT_FILE}"
    fi

    # TODO should check lock and disable
}

# Test run.
! check_root && error_msg "This script must be run as root"
create_out_dir "${OUTPUT}"
# shellcheck disable=SC2164
cd "${OUTPUT}"

info_msg "About to run cfi tests..."
info_msg "Output directory: ${OUTPUT}"

if [ -f /proc/config.gz ]
then
CONFIG_RISCV_USER_CFI=$(zcat /proc/config.gz | grep "CONFIG_RISCV_USER_CFI=")
elif [ -f /boot/config-"$(uname -r)" ]
then
KERNEL_CONFIG_FILE="/boot/config-$(uname -r)"
CONFIG_RISCV_USER_CFI=$(grep "CONFIG_RISCV_USER_CFI=" "${KERNEL_CONFIG_FILE}")
else
exit_on_skip "cfi-pre-requirements" "Kernel config file not available"
fi

[ "${CONFIG_RISCV_USER_CFI}" = "CONFIG_RISCV_USER_CFI=y" ]
exit_on_skip "cfi-pre-requirements" "Kernel config CONFIG_RISCV_USER_CFI=y not enabled"

# Binaries must be provided via an overlay
cfi_run_test
