/******************************************************************************
* Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <pm_api_sys.h>
#include <pm_client.h>
#include <unistd.h>
#include <xipipsu_hw.h>
#include <xipipsu.h>
#include "ipi.h"
#include "gic_setup.h"


#define IPI_INT_ID		XPAR_XIPIPSU_0_INT_ID
#define TEST_CHANNEL_ID	XPAR_XIPIPSU_0_DEVICE_ID

#if defined (versal)
#define SRC_IPI_MASK	(XPAR_XIPIPS_TARGET_PSV_PMC_0_CH0_MASK)
#else
#define SRC_IPI_MASK	(XPAR_XIPIPS_TARGET_PSU_PMU_0_CH1_MASK)
#endif


/* Allocate one callback pointer for each bit in the register */
static IpiCallback IpiCallbacks[28];

/**
 * IpiIrqHandler() - Interrupt handler of IPI peripheral
 *
 * @InstancePtr	Pointer to the IPI data structure
 */
static void IpiIrqHandler(XIpiPsu *InstancePtr)
{
	u32 Mask;
	ssize_t idx;
	u32 IpiMask;

	//xil_printf("%s IPI interrupt received\r\n", __func__);
	/* Read status to determine the source CPU (who generated IPI) */
	Mask = XIpiPsu_GetInterruptStatus(InstancePtr);

	/* Handle all IPIs whose bits are set in the mask */
	while (Mask) {
		IpiMask = Mask & (-Mask);
		idx = __builtin_ctz(IpiMask);

		//xil_printf("IPI interrupt mask = %x\r\n", IpiMask);
		/* If the callback for this IPI is registered execute it */
		if (0U <= idx  && IpiCallbacks[idx])
			IpiCallbacks[idx](InstancePtr);

		/* Clear the interrupt status of this IPI source */
		XIpiPsu_ClearInterruptStatus(InstancePtr, IpiMask);

		/* Clear this IPI in the Mask */
		Mask &= ~IpiMask;
	}
}

/**
 * IpiRegisterCallback() - Interrupt handler of IPI peripheral
 *
 * @IpiInst	Pointer to the IPI data structure
 * @SrcMask	source mask value
 * @Callback Pointer to the IPI call back
 */
XStatus IpiRegisterCallback(XIpiPsu *const IpiInst, const u32 SrcMask,
				IpiCallback Callback)
{
	ssize_t idx;

	if (!Callback) {
		return XST_INVALID_PARAM;
	}

	/* Get index into IpiChannels array */
	idx = __builtin_ctz(SrcMask);
	if (0U > idx) {
		return XST_INVALID_PARAM;
	}

	/* Check if callback is already registered, return failure if it is */
	if (IpiCallbacks[idx]) {
		return XST_FAILURE;
	}

	/* Entry is free, register callback */
	IpiCallbacks[idx] = Callback;

	/* Enable reception of IPI from the SrcMask/CPU */
	XIpiPsu_InterruptEnable(IpiInst, SrcMask);

	return XST_SUCCESS;
}

/**
 * IpiConfigure() - Interrupt handler of IPI peripheral
 *
 * @GicInst	Pointer to the GIC data structure
 * @IpiInst	Pointer to the IPI data structure
 */
static XStatus IpiConfigure(XScuGic *const GicInst, XIpiPsu *const IpiInst)
{
	XStatus Status = XST_FAILURE;
	XIpiPsu_Config *IpiCfgPtr;

	if (NULL == IpiInst) {
		goto done;
	}
	/* Look Up the config data */
	IpiCfgPtr = XIpiPsu_LookupConfig(TEST_CHANNEL_ID);
	if (NULL == IpiCfgPtr) {
		Status = XST_FAILURE;
		xil_printf("%s ERROR in getting CfgPtr\n", __func__);
		goto done;
	}

	/* Init with the Cfg Data */
	Status = XIpiPsu_CfgInitialize(IpiInst, IpiCfgPtr, IpiCfgPtr->BaseAddress);
	if (XST_SUCCESS != Status) {
		xil_printf("%s ERROR #%d in configuring IPI\n", __func__, Status);
		goto done;
	}

	/* Clear Any existing Interrupts */
	XIpiPsu_ClearInterruptStatus(IpiInst, XIPIPSU_ALL_MASK);

	if (NULL == GicInst) {
		goto done;
	}
	Status = XScuGic_Connect(GicInst, IPI_INT_ID, (Xil_ExceptionHandler)IpiIrqHandler, IpiInst);
	if (XST_SUCCESS != Status) {
		xil_printf("%s ERROR #%d in GIC connect\n", __func__, Status);
		goto done;
	}

	/* Enable IPI interrupt at GIC */
	XScuGic_Enable(GicInst, IPI_INT_ID);

done:
	return Status;
}

/**
 * @PmIpiCallback() - Wrapper for the PM callbacks to be called from IPI
 *			interrupt handler
 * @InstancePtr Pointer to the IPI data structure
 */
static void PmIpiCallback(XIpiPsu *const InstancePtr)
{
	XStatus Status;
	u32 pl[PAYLOAD_ARG_CNT];

	Status = XIpiPsu_ReadMessage(InstancePtr, SRC_IPI_MASK, pl,
					PAYLOAD_ARG_CNT, XIPIPSU_BUF_TYPE_MSG);
	if (XST_SUCCESS != Status) {
		xil_printf("ERROR #%d while reading IPI buffer\n", Status);
		return;
	}

	/*
	 * Call callback function if first argument in payload matches
	 * some of the callbacks id.
	 */
	switch (pl[0]) {
		case PM_NOTIFY_CB:
			XPm_NotifyCb(pl[1], pl[2], pl[3]);
			break;
		case PM_INIT_SUSPEND_CB:
	#if defined (versal)
			break;
	#else
			XPm_InitSuspendCb(pl[1], pl[2], pl[3], pl[4]);
			break;
		case PM_ACKNOWLEDGE_CB:
			XPm_AcknowledgeCb(pl[1], pl[2], pl[3]);
			break;
	#endif
		default:
			xil_printf("%s ERROR, unrecognized PM-API ID: %d\n", __func__, pl[0]);
			break;
	}
}

/**
 * IpiWaitForAck() - IPI wait for ack
 *
 * @None
 */
void IpiWaitForAck(void)
{
	//xil_printf("Waiting for acknowledge callback...\n");

	/* Wait for acknowledge - received flag is set from IPI's IrqHandler*/
	while (0U == pm_ack.received) {
		;
	}

	//xil_printf("Received acknowledge: Node=%d, Status=%d, OPP=%d\n",
	//	pm_ack.node, pm_ack.status, pm_ack.opp);

	/* Clear the flag to state that acknowledge is processed */
	pm_ack.received = 0U;
}

/**
 * @IpiInit() - Initialize IPI
 *
 * @GicInst	Pointer to the GIC data structure
 * @InstancePtr	Pointer to the IPI data structure
 */
XStatus IpiInit(XScuGic *const GicInst, XIpiPsu *const InstancePtr)
{
	XStatus Status;

	Status = IpiConfigure(GicInst, InstancePtr);
	if (XST_SUCCESS != Status) {
		xil_printf("IpiConfigure() failed with error: %d\r\n", Status);
		goto done;
	}

	Status = IpiRegisterCallback(InstancePtr, SRC_IPI_MASK, PmIpiCallback);

done:
	return Status;
}

