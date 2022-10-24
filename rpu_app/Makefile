###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################

SHELL := /bin/bash

.PHONY: init
init:
	xsct -eval "setws .; \
	repo -set .;\
	app create -name rpu_app -hw $(BASE_XSA) -os standalone -proc cortexr5_0 -template {Empty Application(C)}; \
	bsp setlib -name xilpm;\
	exec cp ../../rpu_app/main.c rpu_app/src; \
	exec cp ../../rpu_app/rtc.c rpu_app/src; \
	exec cp ../../rpu_app/rtc.h rpu_app/src; \
	exec cp ../../rpu_app/pm_init.c rpu_app/src; \
	exec cp ../../rpu_app/pm_init.h rpu_app/src; \
	exec cp ../../rpu_app/ipi.c rpu_app/src; \
	exec cp ../../rpu_app/ipi.h rpu_app/src; \
	exec cp ../../rpu_app/gic_setup.c rpu_app/src; \
	exec cp ../../rpu_app/gic_setup.h rpu_app/src; \
	exec cp ../../rpu_app/lscript.ld rpu_app/src; \
	platform active $(TARGET_BOARD)_power1; \
	platform generate; "


.PHONY: app
app:
	xsct -eval "setws .; \
	app build -name rpu_app"

