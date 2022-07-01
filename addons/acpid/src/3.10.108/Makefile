#
# Makefile for the Linux ACPI interpreter
#

#
# ACPI Boot-Time Table Parsing
#
#obj-$(CONFIG_X86)		+= blacklist.o

# Power management related files
#acpi-$(CONFIG_ACPI_SLEEP)	+= proc.o


#
# ACPI Bus and Device Drivers
#
#acpi-$(CONFIG_ACPI_DOCK)	+= dock.o
#acpi-$(CONFIG_X86_INTEL_LPSS)	+= acpi_lpss.o
#acpi-$(CONFIG_X86)		+= acpi_cmos_rtc.o
#acpi-$(CONFIG_DEBUG_FS)		+= debugfs.o
acpi-$(CONFIG_ACPI_NUMA)	+= numa.o
#acpi-$(CONFIG_ACPI_PROCFS_POWER) += cm_sbs.o

# These are (potentially) separate modules

# IPMI may be used by other drivers, so it has to initialise before them
#obj-$(CONFIG_ACPI_IPMI)		+= acpi_ipmi.o

#obj-$(CONFIG_ACPI_AC) 		+= ac.o
obj-$(CONFIG_ACPI_BUTTON)	+= button.o
#obj-$(CONFIG_ACPI_FAN)		+= fan.o
#obj-$(CONFIG_ACPI_VIDEO)	+= video.o
#obj-$(CONFIG_ACPI_PCI_SLOT)	+= pci_slot.o
#obj-$(CONFIG_ACPI_CONTAINER)	+= container.o
#obj-$(CONFIG_ACPI_THERMAL)	+= thermal.o
#obj-$(CONFIG_ACPI_HOTPLUG_MEMORY) += acpi_memhotplug.o
#obj-$(CONFIG_ACPI_BATTERY)	+= battery.o
#obj-$(CONFIG_ACPI_SBS)		+= sbshc.o
#obj-$(CONFIG_ACPI_SBS)		+= sbs.o
#obj-$(CONFIG_ACPI_HED)		+= hed.o
#obj-$(CONFIG_ACPI_EC_DEBUGFS)	+= ec_sys.o
#obj-$(CONFIG_ACPI_CUSTOM_METHOD)+= custom_method.o
#obj-$(CONFIG_ACPI_BGRT)		+= bgrt.o
#obj-$(CONFIG_ACPI_I2C)		+= acpi_i2c.o

#obj-$(CONFIG_ACPI_PROCESSOR_AGGREGATOR) += acpi_pad.o
