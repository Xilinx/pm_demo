/******************************************************************************
* Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "pm_init.h"
#include "pm_api_sys.h"
#include "gic_setup.h"
#include "ipi.h"
#include "rtc.h"

extern u32 CountsPerSec;

#if defined(versal)
#define RESUME_ADDR					(0xFFE00000U)
#define SUSPEND_TARGET				(0x1C000003U) /* APU subsystem */
#define WAKEUP_TARGET				PM_DEV_ACPU_0
#define SELF_DEV_ID					PM_DEV_RPU0_0
#define LATENCY_VAL					XPM_MAX_LATENCY
#define NODE_IN_FPD					PM_DEV_SWDT_FPD
#define RTC_DEVICE					PM_DEV_RTC
#define SUSPEND_TYPE				PM_SUSPEND_STATE_SUSPEND_TO_RAM
#define BLOCKING_ACK				0
#define NON_BLOCKING_ACK			0
#define FPD_NODE					PM_POWER_FPD
#define PL_NODE						PM_POWER_PLD
#else
extern void __attribute__((weak)) * _vector_table;
#define RESUME_ADDR					((u32)&_vector_table)
#define SUSPEND_TARGET				NODE_APU
#define WAKEUP_TARGET				NODE_APU_0
#define SELF_DEV_ID					NODE_RPU_0
#define LATENCY_VAL					MAX_LATENCY
#define NODE_IN_FPD					NODE_SATA
#define RTC_DEVICE 					NODE_RTC
#define SUSPEND_TYPE				0
#define BLOCKING_ACK				REQUEST_ACK_BLOCKING
#define NON_BLOCKING_ACK			REQUEST_ACK_NON_BLOCKING
#define FPD_NODE					NODE_FPD
#define PL_NODE						NODE_PLD
#endif

#define DELAY_COUNT(x)				((x) * (u64)XPAR_CPU_CORTEXR5_0_CPU_CLK_FREQ_HZ / 10)
/* Calculate latency from counter ticks to microseconds */
#define CALCULATE_LATENCY(x)		((x) / (CountsPerSec / 1000000))

#define SYNC_APU_MASK				(0x000000FFU)
#define SYNC_RPU_MASK				(0x0000FF00U)
#define SYNC_DELAY_VAL_MASK			(0x00FF0000U)
#define SYNC_DELAY_VAL_SHIFT		(16U)
#define SYNC_ITERATION_CNT_MASK		(0xFF000000U)
#define SYNC_ITERATION_CNT_SHIFT	(24U)
#define SYNC_APU_READY				(0x000000A5U)
#define SYNC_APU_FINISH				(0x0000005AU)
#define SYNC_RPU_SIGNAL				(0x0000AA00U)
#define SYNC_RPU_SIGNAL_APU_SUSPEND	(0x0000AB00U)
#define SYNC_RPU_FINISH				(0x00005500U)
#define SYNC_PL_DOWN				(0x00000011U)
#define SYNC_PL_UP					(0x00000012U)

#define PRINT_RPU_ON_APU_ON			xil_printf("RPU: ******************************** RPU ON, APU ON *********************************\r\n")
#define PRINT_RPU_ON_APU_SUSPEND	xil_printf("RPU: *********************** RPU ON, APU suspended with FPD ON ***********************\r\n")
#define PRINT_RPU_IDLE_APU_SUSPEND	xil_printf("RPU: ********************** RPU Idle, APU suspended with FPD ON **********************\r\n")
#define PRINT_RPU_ON_FPD_OFF		xil_printf("RPU: *********************** RPU ON, APU suspended with FPD OFF **********************\r\n")
#define PRINT_RPU_IDLE_FPD_OFF		xil_printf("RPU: ********************** RPU Idle, APU suspended with FPD OFF *********************\r\n")
#define PRINT_RPU_SUSPENDED_FPD_OFF	xil_printf("RPU: ******************* RPU Suspended, APU suspended with FPD OFF *******************\r\n")

static XIpiPsu IpiInst;
static XRtcPsu RtcInstPtr;
static XScuGic GicInst;

u64 tNotify;
u32 DelayVal;
u32 IterationCnt;

static void Notify_CallBack(XPm_Notifier *const notifier)
{
	tNotify = ReadTime();
}

static XPm_Notifier notifier = {
	.callback = Notify_CallBack,
	.node = FPD_NODE,
	.event = EVENT_STATE_CHANGE,
	.flags = 0,
};

static int InitApp(void)
{
	int Status;

	Status = PmInit(&GicInst, &IpiInst);
	if (Status != XST_SUCCESS) {
		xil_printf("RPU: Error 0x%x in PmInit\r\n");
		goto done;
	}

	Status = PmRtcInit(&GicInst, &RtcInstPtr);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in PmRtcInit\r\n");
		goto done;
	}

done:
	return Status;
}

static void Wait(u32 Seconds)
{
	u64 WaitCount;

	xil_printf("RPU: (%d seconds delay)\r\n", Seconds);
	WaitCount = DELAY_COUNT(Seconds);
	for (; WaitCount > 0; WaitCount--);
}

static int request_suspend(u32 *latency, u32 *fpd_latency)
{
	u64 tStart, tEnd;
	int Status;

	notifier.received = 0;

#if defined(versal)
	(void)latency;
	SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_SIGNAL_APU_SUSPEND);
	tStart = ReadTime();
	while(0 != GetAPU1PwrStatus() || 0 != GetAPU0PwrStatus());
	tEnd = ReadTime();
	Status = XST_SUCCESS;
#else
	tStart = ReadTime();
	Status = XPm_RequestSuspend(SUSPEND_TARGET, NON_BLOCKING_ACK, LATENCY_VAL, 0);
	tEnd = ReadTime();
	IpiWaitForAck();
#endif

	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in RequestSuspend of 0x%x\r\n", Status, SUSPEND_TARGET);
		goto done;
	}
	*latency = CALCULATE_LATENCY(tEnd - tStart);

	PRINT_RPU_ON_APU_SUSPEND;
	Wait(3U);

	xil_printf("RPU: FPD will be off after releasing 0x%x\r\n", NODE_IN_FPD);
	tStart = ReadTime();
	Status = XPm_ReleaseNode(NODE_IN_FPD);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in ReleaseNode of 0x%x\r\n", Status, NODE_IN_FPD);
		goto done;
	}

	/* Block until the notification is received */
	while (0 == notifier.received);
	notifier.received = 0;
	PRINT_RPU_ON_FPD_OFF;
	*fpd_latency = CALCULATE_LATENCY(tNotify - tStart);

done:
	return Status;
}

static int request_wakeup(u32 *latency, u32 *pu0_latency, u32 *fpd_latency)
{
	u64 tStart, tEnd, tpu0_up;
	int Status;

	notifier.received = 0;

#if defined(versal)
	(void)fpd_latency;
#else
	tStart = ReadTime();
	Status = XPm_RequestNode(NODE_IN_FPD, PM_CAP_ACCESS, 0, BLOCKING_ACK);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_IN_FPD);
		goto done;
	}

	/* Block until the notification is received */
	while (0 == notifier.received);
	*fpd_latency = CALCULATE_LATENCY(tNotify - tStart);

	PRINT_RPU_ON_APU_SUSPEND;
#endif

	tStart = ReadTime();
	Status = XPm_RequestWakeUp(WAKEUP_TARGET, 0, 0, BLOCKING_ACK);
	tpu0_up = ReadTime();
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in RequestWakeup of 0x%x\r\n", Status, WAKEUP_TARGET);
		goto done;
	}

#if defined(versal)
	Status = XPm_RequestNode(NODE_IN_FPD, PM_CAP_ACCESS, 0, BLOCKING_ACK);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_IN_FPD);
		goto done;
	}
#endif

	/* Wait till target application is ready */
	SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_SIGNAL);
	SyncWaitForReady(SYNC_APU_READY);
	tEnd = ReadTime();
	SyncClearReady(SYNC_APU_MASK);

	PRINT_RPU_ON_APU_ON;

	*pu0_latency = CALCULATE_LATENCY(tpu0_up - tStart);
	*latency = CALCULATE_LATENCY(tEnd - tStart);

done:
	return Status;
}

static int measure_latency(void)
{
	u32 iteration, latency, pu0_latency, fpd_latency;
	u32 susp_min = ~0, susp_max = 0, susp_avg = 0;
	u32 fpd_off_min = ~0, fpd_off_max = 0, fpd_off_avg = 0;
	u32 wake_min = ~0, wake_max = 0, wake_avg = 0;
	u32 pu0_wake_min = ~0, pu0_wake_max = 0, pu0_wake_avg = 0;

#if !defined(versal)
	u32 fpd_on_min = ~0, fpd_on_max = 0, fpd_on_avg = 0;
#endif

	u64 susp_total = 0, wake_total = 0, pu0_wake_total = 0;
	u64 fpd_on_total = 0, fpd_off_total = 0;
	int Status;

	xil_printf("RPU: Latency Measurement Start. Total iteration is %d\r\n", IterationCnt);
	for (iteration = 0; iteration < IterationCnt; iteration++) {

		xil_printf("RPU: Latency measurement iteration count : %d\r\n", iteration + 1);

		PRINT_RPU_ON_APU_ON;

		/* Measure suspend latency */
		Status = request_suspend(&latency, &fpd_latency);
		if (XST_SUCCESS != Status) {
			goto done;
		}

		susp_min = (latency < susp_min) ? latency : susp_min;
		susp_max = (latency > susp_max) ? latency : susp_max;
		susp_total += latency;

		fpd_off_min = (fpd_latency < fpd_off_min) ? fpd_latency : fpd_off_min;
		fpd_off_max = (fpd_latency > fpd_off_max) ? fpd_latency : fpd_off_max;
		fpd_off_total += fpd_latency;

		Wait(3U);

		/* Measure wakeup latency */
		Status = request_wakeup(&latency, &pu0_latency, &fpd_latency);
		if (XST_SUCCESS != Status) {
			goto done;
		}

		wake_min = (latency < wake_min) ? latency : wake_min;
		wake_max = (latency > wake_max) ? latency : wake_max;
		wake_total += latency;

		pu0_wake_min = (pu0_latency < pu0_wake_min) ? pu0_latency : pu0_wake_min;
		pu0_wake_max = (pu0_latency > pu0_wake_max) ? pu0_latency : pu0_wake_max;
		pu0_wake_total += pu0_latency;

#if !defined(versal)
		fpd_on_min = (fpd_latency < fpd_on_min) ? fpd_latency : fpd_on_min;
		fpd_on_max = (fpd_latency > fpd_on_max) ? fpd_latency : fpd_on_max;
		fpd_on_total += fpd_latency;
#endif
		Wait(3U);
	}

	susp_avg = susp_total / IterationCnt;
	wake_avg = wake_total / IterationCnt;
	fpd_off_avg = fpd_off_total / IterationCnt;
	pu0_wake_avg = pu0_wake_total / IterationCnt;

#if !defined(versal)
	fpd_on_avg = fpd_on_total / IterationCnt;
#endif

	xil_printf("RPU: Request Suspend Latency of Linux in micro seconds: Min: %ld, Max: %ld, Avg: %ld\r\n",
			   susp_min, susp_max, susp_avg);
	xil_printf("RPU: FPD OFF Latency in micro seconds: Min: %ld, Max: %ld, Avg: %ld\r\n",
			   fpd_off_min, fpd_off_max, fpd_off_avg);

#if !defined(versal)
	xil_printf("RPU: FPD ON Latency in micro seconds: Min: %ld, Max: %ld, Avg: %ld\r\n",
			   fpd_on_min, fpd_on_max, fpd_on_avg);
#endif

	xil_printf("RPU: Wakeup Latency of APU0 in micro seconds: Min: %ld, Max: %ld, Avg: %ld\r\n",
			   pu0_wake_min, pu0_wake_max, pu0_wake_avg);
	xil_printf("RPU: Wakeup Latency of Linux in micro seconds: Min: %ld, Max: %ld, Avg: %ld\r\n",
			   wake_min, wake_max, wake_avg);
	xil_printf("RPU: Latency Measurement Done\r\n");

done:
	return Status;
}

static int prepare_suspend(void)
{
	XStatus Status;

	Status = XPm_SetWakeUpSource(SELF_DEV_ID, RTC_DEVICE, 1);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in SetWakeUpSource of RTC\r\n", Status);
		goto done;
	}

	Status = XPm_SelfSuspend(SELF_DEV_ID, LATENCY_VAL, SUSPEND_TYPE, RESUME_ADDR);
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in SelfSuspend\r\n", Status);
		goto done;
	}

#if !defined(versal)
	u32 SramMemList[] = {
		NODE_TCM_0_A,
		NODE_TCM_0_B,
		NODE_TCM_1_A,
		NODE_TCM_1_B,
	};
	u32 OtherDevList[] = {
		NODE_OCM_BANK_0,
		NODE_OCM_BANK_1,
		NODE_OCM_BANK_2,
		NODE_OCM_BANK_3,
		NODE_I2C_0,
		NODE_I2C_1,
		NODE_SD_1,
		NODE_QSPI,
		NODE_ADMA,
	};
	u32 Idx;

	for (Idx = 0; Idx < PM_ARRAY_SIZE(SramMemList); Idx++) {
		Status = XPm_SetRequirement(SramMemList[Idx], PM_CAP_CONTEXT, 0, REQUEST_ACK_NO);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in SetRequirement of 0x%x\r\n", Status, SramMemList[Idx]);
			goto done;
		}
	}

	for (Idx = 0; Idx < PM_ARRAY_SIZE(OtherDevList); Idx++) {
		Status = XPm_SetRequirement(OtherDevList[Idx], 0, 0, REQUEST_ACK_NO);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in SetRequirement of 0x%x\r\n", Status, OtherDevList[Idx]);
			goto done;
		}
	}
#endif

done:
	return Status;
}

int main()
{
	enum XPmBootStatus BootStatus;
	int Status = XST_FAILURE;
	u32 ApuSyncValue = 0;

#if !defined(versal)
	u64 tStart, tEnd;
	u32 PlLatency;
#endif

	BootStatus = XPm_GetBootStatus();
	if (PM_INITIAL_BOOT == BootStatus) {
		/* Add delay to avoid print mix-up */
		Wait(3);
		xil_printf("RPU: INITIAL BOOT\r\n");

		Status = InitApp();
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in InitApp\r\n", Status);
			goto done;
		}

		Status = XPm_RequestNode(NODE_IN_FPD, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_IN_FPD);
			goto done;
		}

#if !defined(versal)
		Status = XPm_RequestNode(NODE_UART_0, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_UART_0);
			goto done;
		}
#endif

		Status = XPm_RegisterNotifier(&notifier);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RegisterNotifier\r\n", Status);
			goto done;
		}
	} else if (PM_RESUME == BootStatus) {
#if !defined(versal)
		Status = XPm_RequestNode(NODE_UART_0, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_UART_0);
			goto done;
		}
#endif

		xil_printf("RPU: RESUMED\r\n");

		/* Timer is already counting, just enable interrupts */
		Status = GicResume(&GicInst);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in GicResume\r\n", Status);
			goto done;
		}

		PRINT_RPU_ON_FPD_OFF;
		Wait(DelayVal);

#if !defined(versal)
		Status = XPm_RequestNode(NODE_IN_FPD, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_IN_FPD);
			goto done;
		}

		PRINT_RPU_IDLE_APU_SUSPEND;
#else
		PRINT_RPU_IDLE_FPD_OFF;
#endif
		SetRtcAlarm(&RtcInstPtr, DelayVal);
		__asm__("wfi");

		Status = XPm_RequestWakeUp(WAKEUP_TARGET, 0, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestWakeup of 0x%x\r\n", Status, WAKEUP_TARGET);
			goto done;
		}

#if defined(versal)
		Status = XPm_RequestNode(NODE_IN_FPD, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, NODE_IN_FPD);
			goto done;
		}
#endif

		SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_FINISH);
		SyncWaitForReady(SYNC_APU_READY);
		SyncClearReady(SYNC_APU_MASK);
		PRINT_RPU_ON_APU_ON;

		do {
			SetRtcAlarm(&RtcInstPtr, DelayVal);
			__asm__("wfi");

			/* Wait till target application is ready */
			SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_SIGNAL);
			Wait(1);
			ApuSyncValue = SyncGetValue(SYNC_APU_MASK);
			SyncClearReady(SYNC_APU_MASK);
		} while (ApuSyncValue != SYNC_APU_FINISH);

#if !defined(versal)
		SyncWaitForReady(SYNC_PL_UP);
		SyncClearReady(SYNC_PL_UP);
		xil_printf("RPU: Powering up PL\r\n");
		tStart = ReadTime();
		Status = XPm_RequestNode(NODE_PL, PM_CAP_ACCESS, 0, BLOCKING_ACK);
		tEnd = ReadTime();
		if (XST_SUCCESS != Status) {
			xil_printf("RPU: Error 0x%x in RequestNode of 0x%x\r\n", Status, PL_NODE);
			goto done;
		}
		PlLatency = CALCULATE_LATENCY(tEnd - tStart);
		xil_printf("RPU: PL ON Latency in micro seconds: %ld\r\n", PlLatency);
#endif
	} else {
		xil_printf("RPU: Invalid Boot Status\r\n");
		Status = XST_FAILURE;
		goto done;
	}

#if !defined(versal)
	SyncWaitForReady(SYNC_PL_DOWN);
	SyncClearReady(SYNC_PL_DOWN);

	xil_printf("RPU: Powering down PL\r\n");
	tStart = ReadTime();
	Status = XPm_ForcePowerDown(PL_NODE, BLOCKING_ACK);
	tEnd = ReadTime();
	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in ForcePowerDown of 0x%x\r\n", Status, PL_NODE);
		goto done;
	}
	PlLatency = CALCULATE_LATENCY(tEnd - tStart);
	xil_printf("RPU: PL OFF Latency in micro seconds: %ld\r\n", PlLatency);
#endif

	SyncWaitForReady(SYNC_APU_READY);
	SyncClearReady(SYNC_APU_MASK);

	/* Get delay value between 2 power modes */
	DelayVal = SyncGetValue(SYNC_DELAY_VAL_MASK) >> SYNC_DELAY_VAL_SHIFT;
	if (DelayVal < 10U) {
		DelayVal = 10U;
	}
	xil_printf("RPU: DelayVal = %d\r\n", DelayVal);

	/* Get number of iterations for latency measurement */
	IterationCnt = SyncGetValue(SYNC_ITERATION_CNT_MASK) >> SYNC_ITERATION_CNT_SHIFT;
	if (IterationCnt > 5U) {
		IterationCnt = 5U;
	}

	do {
		SetRtcAlarm(&RtcInstPtr, DelayVal);
		__asm__("wfi");

		/* Wait till target application is ready */
		SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_SIGNAL);
		Wait(1);
		ApuSyncValue = SyncGetValue(SYNC_APU_MASK);
		SyncClearReady(SYNC_APU_MASK);
	} while (ApuSyncValue != SYNC_APU_FINISH);

	if (IterationCnt > 0U) {
		xil_printf("RPU: IterationCnt = %d\r\n", IterationCnt);

		Status = measure_latency();
		if (Status != XST_SUCCESS) {
			xil_printf("RPU: Error 0x%x in Latency measurement of APU\r\n", Status);
			goto done;
		}
	} else {
		xil_printf("RPU: Skipping APU Latency measurement\r\n");
	}

#if defined(versal)
	SyncSetMask(SYNC_RPU_MASK, SYNC_RPU_SIGNAL_APU_SUSPEND);
	while(0 != GetAPU1PwrStatus() || 0 != GetAPU0PwrStatus());
	Status = XST_SUCCESS;
#else
	Status = XPm_RequestSuspend(SUSPEND_TARGET, NON_BLOCKING_ACK, LATENCY_VAL, 0);
	IpiWaitForAck();
#endif

	if (XST_SUCCESS != Status) {
		xil_printf("RPU: Error 0x%x in RequestSuspend of 0x%x\r\n", Status, SUSPEND_TARGET);
		goto done;
	}
	Wait(3);
	PRINT_RPU_IDLE_APU_SUSPEND;
	SetRtcAlarm(&RtcInstPtr, DelayVal);
	__asm__("wfi");

	Status = XPm_ReleaseNode(NODE_IN_FPD);
	if (Status != XST_SUCCESS) {
		xil_printf("RPU: Error 0x%x in ReleaseNode of 0x%x\r\n", Status, NODE_IN_FPD);
		goto done;
	}
	PRINT_RPU_ON_FPD_OFF;
	Wait(DelayVal);

	SetRtcAlarm(&RtcInstPtr, DelayVal);
	PRINT_RPU_IDLE_FPD_OFF;
	__asm__("wfi");

	SetRtcAlarm(&RtcInstPtr, DelayVal);
	prepare_suspend();
	GicSuspend(&GicInst);
	PRINT_RPU_SUSPENDED_FPD_OFF;

#if !defined(versal)
	Status = XPm_ReleaseNode(NODE_UART_0);
	if (Status != XST_SUCCESS) {
		xil_printf("RPU: Error 0x%x in ReleaseNode of NODE_UART_0\r\n", Status);
		goto done;
	}
#endif
	XPm_ClientSuspendFinalize();

done:
	return Status;
}
