/******************************************************************************
* Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "pm_api_sys.h"
#include "rtc.h"

#define RTC_INT_ID		(XPAR_XRTCPSU_ALARM_INTR)
#if defined(versal)
#define RTC_DEVICE_ID		XPAR_XRTCPSU_0_DEVICE_ID	
#define RTC_DEVICE		PM_DEV_RTC
#define QOS_VAL			XPM_MAX_QOS
#else
#define RTC_DEVICE_ID           XPAR_XRTCPSU_0_DEVICE_ID
#define RTC_DEVICE		NODE_RTC
#define QOS_VAL			MAX_QOS
#endif

static void RtcIrqHandler(XRtcPsu *RtcInstPtr, u32 Event)
{
	//xil_printf("RPU: %s RTC interrupt received\r\n", __func__);
	/* Alarm event */
	if (XRTCPSU_EVENT_ALARM_GEN == Event) {
		xil_printf("RPU: RTC Alarm generated.\n\r");
	}
	XRtcPsu_ClearInterruptMask(RtcInstPtr, XRTC_INT_DIS_ALRM_MASK);
	XRtcPsu_ResetAlarm(RtcInstPtr);
}

void SetRtcAlarm(XRtcPsu *RtcInstPtr, u32 AlarmPeriod)
{
	u32 CurrentTime, Alarm;

	XRtcPsu_SetInterruptMask(RtcInstPtr, XRTC_INT_EN_ALRM_MASK);

	xil_printf("RPU: (%d seconds RTC timer)\r\n", AlarmPeriod);
	CurrentTime = XRtcPsu_GetCurrentTime(RtcInstPtr);
	Alarm = CurrentTime + AlarmPeriod;
	XRtcPsu_SetAlarm(RtcInstPtr,Alarm,1U);
}

int PmRtcInit(XScuGic *const GicInst, XRtcPsu *RtcInstPtr)
{
	int Status = XST_FAILURE;
	XRtcPsu_Config *Config;

#if defined(versal)
	Status = XPm_RequestNode(RTC_DEVICE, PM_CAP_ACCESS, QOS_VAL, 0);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: XPm_RequestNode failed with error: %d\n", Status);
		goto done;
	}
#endif

	Config = XRtcPsu_LookupConfig(RTC_DEVICE_ID);
	if (NULL == Config) {
		xil_printf("RPU: %s ERROR in getting CfgPtr\n", __func__);
		goto done;
	}

	Status = XRtcPsu_CfgInitialize(RtcInstPtr, Config, Config->BaseAddr);
	if (XST_SUCCESS != Status) {			
		xil_printf("RPU: %s ERROR in_CfgInitialize\n", __func__);
		goto done;
	}

	XRtcPsu_SetHandler(RtcInstPtr, (XRtcPsu_Handler)RtcIrqHandler, RtcInstPtr);

	Status = XScuGic_Connect(GicInst, RTC_INT_ID,
				 (Xil_ExceptionHandler)XRtcPsu_InterruptHandler,
				 (void *)RtcInstPtr);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: %s ERROR #%d in GIC connect\n", __func__, Status);
		goto done;
	}

	/* Enable RTC interrupt at GIC */
	XScuGic_Enable(GicInst, RTC_INT_ID);

done:
	return Status;
}

