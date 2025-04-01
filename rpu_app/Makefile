###############################################################################
# Copyright (C) 2023 - 2025, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

SHELL := /bin/bash
BOARD ?= vck190
BASE_XSA ?= ../images/vck190_power1.xsa

.PHONY: rpu_app
rpu_app:
ifeq ($(wildcard rpu_app/.*),)
	xsct -eval "setws .; \
	repo -set .; \
	app create -name $@ -hw $(BASE_XSA) -os standalone -proc cortexr5_0 -template {Empty Application(C)}; \
	bsp setlib -name xilpm;\
	exec cp ../../$@/main.c      $@/src; \
	exec cp ../../$@/rtc.c       $@/src; \
	exec cp ../../$@/rtc.h       $@/src; \
	exec cp ../../$@/pm_init.c   $@/src; \
	exec cp ../../$@/pm_init.h   $@/src; \
	exec cp ../../$@/ipi.c       $@/src; \
	exec cp ../../$@/ipi.h       $@/src; \
	exec cp ../../$@/gic_setup.c $@/src; \
	exec cp ../../$@/gic_setup.h $@/src; \
	exec cp ../../$@/lscript.ld  $@/src; \
	platform active $(BOARD)_power1; \
	platform generate; \
	app build -name $@"
else
	cp ../../$@/main.c $@/src
	xsct -eval "setws .; \
	repo -set .; \
	app clean -name $@; \
	app build -name $@"
endif

