/******************************************************************************
* Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "pm_api_sys.h"
#include "pm_init.h"
#include "xil_types.h"
#include "xil_io.h"

#if defined(versal)
#define PGGS3_REG			(0xF111005C)
#define IOU_SCNTRS_BASE_ADDR		(0xFF140000)
#define GLOBAL_STATUS_REG		(0xFFC90100)
#else
#define PGGS3_REG			(0xFFD8005C)
#define IOU_SCNTRS_BASE_ADDR		(0xFF260000)
#endif

u32 CountsPerSec = 0;

u64 ReadTime(void)
{
	u64 Time = 0x0U;

	Time = (u64)Xil_In32(IOU_SCNTRS_BASE_ADDR + 0x8U);
	Time |= ((u64)Xil_In32(IOU_SCNTRS_BASE_ADDR + 0xCU) << 32);

	CountsPerSec = Xil_In32(IOU_SCNTRS_BASE_ADDR + 0x20U);
	
	return Time;
}

XStatus PmInit(XScuGic *const GicInst, XIpiPsu *const IpiInst)
{
        int Status;

	/* GIC Initialize */
	if (NULL != GicInst) {
		Status = GicSetupInterruptSystem(GicInst);
		if (Status != XST_SUCCESS) {
			xil_printf("GicSetupInterruptSystem() failed with error: %d\r\n", Status);
			goto done;
		}
	}

	/* IPI Initialize */
        Status = IpiInit(GicInst, IpiInst);
        if (XST_SUCCESS != Status) {
                xil_printf("IpiInit() failed with error: %d\r\n", Status);
                goto done;
        }

	/* XilPM Initialize */
        Status = XPm_InitXilpm(IpiInst);
        if (XST_SUCCESS != Status) {
                xil_printf("XPm_InitXilpm() failed with error: %d\r\n", Status);
                goto done;
        }

#if defined(__arm__) && defined(versal)
	/* TTC_3 is required for sleep functionality */
	Status = XPm_RequestNode(PM_DEV_TTC_2, PM_CAP_ACCESS, 0, 0);
	if (XST_SUCCESS != Status) {
		xil_printf("XPm_RequestNode of TTC_3 is failed with error: %d\r\n", Status);
		goto done;
	}
#endif

	/* Finalize Initialization */
        Status = XPm_InitFinalize();
        if (XST_SUCCESS != Status) {
                xil_printf("XPm_initfinalize() failed\r\n");
                goto done;
        }

done:
        return Status;
}

/* Wait for other processor to write value in PGGS3 register */ 
void SyncWaitForReady(const u32 Value)
{
	while (Value != (Xil_In32(PGGS3_REG) & Value));
}

/* Clear value mask in PGGS3 register */
void SyncClearReady(const u32 Mask)
{
	Xil_Out32(PGGS3_REG, (Xil_In32(PGGS3_REG) & ~(Mask)));
}

/* Set value mask in PGGS3 register */
void SyncSetMask(const u32 Mask, const u32 Value)
{
	u32 l_Val;

        l_Val = Xil_In32(PGGS3_REG);
        l_Val = (l_Val & (~Mask)) | (Mask & Value);

        Xil_Out32(PGGS3_REG, l_Val);
}

#if defined(versal)
/* Get power status for APU0 */
u32 GetAPU0PwrStatus()
{
	return (Xil_In32(GLOBAL_STATUS_REG) & 1);	
}

/* Get power status for APU1 */
u32 GetAPU1PwrStatus()
{
	return (Xil_In32(GLOBAL_STATUS_REG) & 2);
}
#endif
/* Get value from PGGS3 register */
u32 SyncGetValue(const u32 Mask)
{
        return (Xil_In32(PGGS3_REG) & Mask);
}
