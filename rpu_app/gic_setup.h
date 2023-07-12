/******************************************************************************
* Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#ifndef GIC_SETUP_H_
#define GIC_SETUP_H_

#include <xscugic.h>

XStatus GicSetupInterruptSystem(XScuGic *GicInst);
XStatus GicResume(XScuGic *const GicInst);
void    GicSuspend(XScuGic *const GicInst);

#endif /* GIC_SETUP_H_ */

