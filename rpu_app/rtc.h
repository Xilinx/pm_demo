/******************************************************************************
* Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#ifndef _RTC_H_
#define _RTC_H_

#include "xparameters.h"	/* SDK generated parameters */
#include "xrtcpsu.h"		/* RTCPSU device driver */
#include "xscugic.h"

XStatus PmRtcInit(XScuGic *const GicInst, XRtcPsu *RtcInstPtr);
void    SetRtcAlarm(XRtcPsu *RtcInstPtr, u32 AlarmPeriod);

#endif /* _RTC_H_ */

