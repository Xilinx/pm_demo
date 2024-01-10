/******************************************************************************
* Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#ifndef PM_INIT_H_
#define PM_INIT_H_

#include "ipi.h"
#include "gic_setup.h"

XStatus PmInit(XScuGic *const GicInst, XIpiPsu *const IpiInst);
void    SyncWaitForReady(const u32 Value);
void    SyncClearReady(const u32 Mask);
void    SyncSetMask(const u32 Mask, const u32 Value);
#if defined(versal)
u32 GetApu0PwrStatus();
u32 GetApu1PwrStatus();
#endif
u32 SyncGetValue(const u32 Mask);
u64 ReadTime(void);

#endif /* PM_INIT_H_ */

