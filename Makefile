#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
FS_IMAGE_ZIP_FILE_URL ?= http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip
FS_IMAGE_ZIP_FILE_SHA256SUM ?= a50237c2f718bd8d806b96df5b9d2174ce8b789eda1f03434ed2213bbca6c6ff

KERNEL_URL ?= https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/kernel-qemu-4.19.50-buster
KERNEL_FILE_SHA256SUM ?= 47d1fb61fc2d6ffa87a3cc44b0a2209cb455d45b35c41dc0cdd2862a1e553ab3

DTB_URL ?= https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb
DTB_FILE_SHA256SUM ?= 1e72b73b6a5295d7929fe1993ea6e6af05d49e80a47b929538dc4bc3087af3a9


#------------------------------------------------------------------------------
# Variable assignments
#------------------------------------------------------------------------------
project_abs_path := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
build_dir := build
cache_dir := .cache
scripts_dir := scripts

prepare_dirs := \
	$(build_dir) \
	$(cache_dir)

_fs_image_zip_file_name := $(notdir $(FS_IMAGE_ZIP_FILE_URL))
fs_image_zip_file := $(cache_dir)/$(_fs_image_zip_file_name)
build_fs_image_file := $(build_dir)/filesystem.img

cached_kernel_file := $(cache_dir)/$(notdir $(KERNEL_URL))
cached_dtb_file := $(cache_dir)/$(notdir $(DTB_URL))
build_kernel_file := $(build_dir)/kernel
build_dtb_file := $(build_dir)/dtb

qemu_configured_sentinel := $(build_dir)/MAKEFILE-QEMU-CONFIGURED-SENTINEL
qemu_started_sentinel := $(build_dir)/MAKEFILE-QEMU-STARTED-SENTINEL

export RASPI_FILESYSTEM_IMAGE_FILE := $(project_abs_path)/$(build_fs_image_file)
export RASPI_KERNEL_FILE := $(project_abs_path)/$(build_kernel_file)
export RASPI_DTB_FILE := $(project_abs_path)/$(build_dtb_file)


.PHONY: all prepare clean copy-cached-files distclean qemu-start qemu-configure qemu-stop qemu-force-stop

all: copy-cached-files


#------------------------------------------------------------------------------
# QEMU tasks
#------------------------------------------------------------------------------
qemu-start: | $(qemu_started_sentinel)

$(qemu_started_sentinel): | copy-cached-files
	./$(scripts_dir)/qemu-start.exp
	touch '$(qemu_started_sentinel)'

qemu-configure: | $(qemu_configured_sentinel)

$(qemu_configured_sentinel): | qemu-start
	./$(scripts_dir)/qemu-configure.exp
	touch '$(qemu_configured_sentinel)'

qemu-stop:
	./$(scripts_dir)/qemu-stop.exp
	rm '$(qemu_started_sentinel)'

qemu-force-stop:
	./$(scripts_dir)/qemu-force-stop.exp
	rm '$(qemu_started_sentinel)'


#------------------------------------------------------------------------------
# Fetching and setup tasks
#------------------------------------------------------------------------------
copy-cached-files: | $(build_fs_image_file) $(build_kernel_file) $(build_dtb_file)

$(cached_kernel_file): | prepare
	wget --timeout=300 --progress=dot:mega "$(KERNEL_URL)?raw=true" --output-document '$@.temp-unchecked'
	echo '$(KERNEL_FILE_SHA256SUM) $@.temp-unchecked' | sha256sum --check --status
	mv -v '$@.temp-unchecked' '$@'

$(cached_dtb_file): | prepare
	wget --timeout=120 --progress=dot "$(DTB_URL)?raw=true" --output-document '$@.temp-unchecked'
	echo '$(DTB_FILE_SHA256SUM) $@.temp-unchecked' | sha256sum --check --status
	mv -v '$@.temp-unchecked' '$@'

$(fs_image_zip_file): | prepare
	wget --timeout=120 --progress=dot:giga '$(FS_IMAGE_ZIP_FILE_URL)' --output-document '$@.temp-unchecked'
	echo '$(FS_IMAGE_ZIP_FILE_SHA256SUM) $@.temp-unchecked' | sha256sum --check --status
	mv -v '$@.temp-unchecked' '$@'

$(build_fs_image_file): $(fs_image_zip_file)
	unzip -od '$(dir $@)' '$<'
	mv -v '$(dir $@)$(basename $(notdir $<))$(suffix $@)' '$@'
	touch '$@'

$(build_kernel_file): $(cached_kernel_file)
	cp -vf '$<' '$@'

$(build_dtb_file): $(cached_dtb_file)
	cp -vf '$<' '$@'


#------------------------------------------------------------------------------
# Helper tasks
#------------------------------------------------------------------------------
prepare: | $(prepare_dirs)

$(prepare_dirs): %:
	install -d '$@'

clean:
	rm -Rf '$(build_dir)'

distclean: | clean
	rm -Rf '$(cache_dir)'
