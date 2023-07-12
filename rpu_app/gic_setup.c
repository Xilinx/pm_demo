/******************************************************************************
* Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <xscugic_hw.h>
#include "gic_setup.h"
#include "pm_client.h"


#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID

typedef struct {
	void *CallBackRef;
	u8    Enabled;
} GicIrqEntry;

static GicIrqEntry GicIrqTable[XSCUGIC_MAX_NUM_INTR_INPUTS];


/**
 * @GicSetupInterruptSystem() - Setup GIC
 *
 * @GicInst	Pointer to the GIC data structure
 */
XStatus GicSetupInterruptSystem(XScuGic *GicInst)
{
	XStatus Status;

	XScuGic_Config *GicCfgPtr = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == GicCfgPtr) {
		xil_printf("XScuGic_LookupConfig() failed\r\n");
		goto done;
	}

	Status = XScuGic_CfgInitialize(GicInst, GicCfgPtr, GicCfgPtr->CpuBaseAddress);
	if (XST_SUCCESS != Status) {
		xil_printf("XScuGic_CfgInitialize() failed with error: %d\r\n", Status);
		goto done;
	}

	/*
	 * Connect the interrupt controller interrupt Handler to the
	 * hardware interrupt handling logic in the processor.
	 */
#if defined (__aarch64__)
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_FIQ_INT,
#elif defined (__arm__)
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
#endif
		(Xil_ExceptionHandler)XScuGic_InterruptHandler, GicInst);
	Xil_ExceptionEnable();

done:
	return Status;
}

/**
 * @GicResume() - Resume GIC
 *
 * @GicInst	Pointer to the GIC data structure
 */
XStatus GicResume(XScuGic *GicInst)
{
	XStatus Status;
	u32 i;

	GicInst->IsReady = 0U;

#if defined (GICv3)
	XScuGic_MarkCoreAwake(GicInst);
#endif

	XScuGic_Config *GicCfgPtr = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == GicCfgPtr) {
		xil_printf("XScuGic_LookupConfig() failed\r\n");
		goto done;
	}

	Status = XScuGic_CfgInitialize(GicInst, GicCfgPtr, GicCfgPtr->CpuBaseAddress);
	if (XST_SUCCESS != Status) {
		xil_printf("XScuGic_CfgInitialize() failed with error: %d\r\n", Status);
		goto done;
	}

	/* Restore handler pointers and enable interrupt if it was enabled */
	for (i = 0U; XSCUGIC_MAX_NUM_INTR_INPUTS > i; i++) {
		GicInst->Config->HandlerTable[i].CallBackRef = GicIrqTable[i].CallBackRef;

		if (GicIrqTable[i].Enabled) {
			XScuGic_Enable(GicInst, i);
		}
	}
	Xil_ExceptionEnable();

done:
	return Status;
}

/**
 * @GicSuspend() - GicSuspend handler
 *
 * @GicInst	Pointer to the GIC data structure
 */
void GicSuspend(XScuGic *const GicInst)
{
	u32 i;
	u32 Reg;
	u32 Mask;

	for (i = 0U; XSCUGIC_MAX_NUM_INTR_INPUTS > i; i++) {

		GicIrqTable[i].CallBackRef = GicInst->Config->HandlerTable[i].CallBackRef;

		Mask = 0x00000001U << (i % 32U);
		Reg  = XScuGic_DistReadReg(GicInst, XSCUGIC_ENABLE_SET_OFFSET +
					((i / 32U) * 4U));
		GicIrqTable[i].Enabled = (Mask & Reg) ? 1U : 0U;
	}

#if defined (GICv3)
	XScuGic_MarkCoreAsleep(GicInst);
#endif
}

