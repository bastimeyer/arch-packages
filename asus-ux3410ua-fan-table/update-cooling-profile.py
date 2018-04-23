#!/usr/bin/env python

"""Tweak cooling profile to keep cooling fan quiet when laptop is idle.

Do this by rewriting thermal tipping points in Embedded Controller memory via ACPI.
Requires "acpi_call" kernel module to be loaded.

Based on @afilipovich's proof-of-concept script:
https://github.com/daringer/asus-fan/issues/44#issuecomment-307589414
https://github.com/afilipovich/asus_ux360uak/blob/master/update_cooling_profile.py
"""

import sys
import logging as log
log.basicConfig(format='%(asctime)s %(levelname)s %(process)d %(processName)s %(message)s', level=log.INFO)


class ThermalTable:
    offset = 0x537
    default_tipping_points = [35, 40, 45, 50, 55, 60, 65, 80]
    quiet_tipping_points = [52, 54, 56, 58, 60, 65, 70, 80]

    def call_acpi(self, command):
        with open('/proc/acpi/call', 'w') as acpi_call:
            log.info(command)
            acpi_call.write(command)
            acpi_call.close()
        with open('/proc/acpi/call') as acpi_call:
            response = acpi_call.read()
            acpi_call.close()
        return response

    def update_table(self, tipping_points):
        assert len(tipping_points) <= 8
        for i, t in enumerate(tipping_points):
            addr = self.offset + i
            cmd = '\_SB.PCI0.LPCB.EC0.WRAM {} {}'.format(hex(addr), hex(t))
            self.call_acpi(cmd)

    def set_quiet_profile(self):
        log.info('Setting quiet cooling profile. It may take a few minutes for it to become active.')
        self.update_table(self.quiet_tipping_points)

    def set_default_profile(self):
        log.info('Setting default cooling profile.')
        self.update_table(self.default_tipping_points)


def main():
    tt = ThermalTable()
    if len(sys.argv) == 2 and sys.argv[1] == "on":
        tt.set_quiet_profile()
    else:
        tt.set_default_profile()

if __name__ == '__main__':
    main()
