/*
   STM32F103 registers
*/
    /* RAM */
    .equ RAM_ADR, 0x20000000 
    .equ RAM_SIZE, 0x20000
    .equ RAM_END, RAM_ADR+RAM_SIZE

   /* RAM bit band alias */
      .equ RAM_BIT_ALIAS, 0x22000000

    /* FLASH MEMORY */
    /* memory reported by MCU */
    .equ FLASH_ADR,  0x8000000 
    .equ FLASH_SIZE, 0x0080000
    .equ FLASH_END, FLASH_ADR+FLASH_SIZE
     // erase block size
    .equ SECTOR0_ADR, 0x8000000  
    .equ SECTOR0_SIZE, 16384  // 0x0800 0000 - 0x0800 3FFF
    .equ SECTOR1_ADR, 0x8004000
    .equ SECTOR1_SIZE, 16384  // 0x0800 4000 - 0x0800 7FFF
    .equ SECTOR2_ADR, 0x8008000 
    .equ SECTOR2_SIZE, 16384  // 0x0800 8000 - 0x0800 BFFF
    .equ SECTOR3_ADR, 0x800C000
    .equ SECTOR3_SIZE, 16384  // 0x0800 C000 - 0x0800 FFFF
    .equ SECTOR4_ADR, 0x8010000
    .equ SECTOR4_SIZE, 65536  // 0x0801 0000 - 0x0801 FFFF
    .equ SECTOR5_ADR, 0x08020000
    .equ SECTOR5_SIZE, 131072 // 0x0802 0000 - 0x0803 FFFF
    .equ SECTOR6_ADR, 0x08040000
    .equ SECTOR6_SIZE, 131072 // 0x0804 0000 - 0x0805 FFFF
    .equ SECTOR7_ADR, 0x08060000
    .equ SECTOR7_SIZE, 131072 // 0x0806 0000 - 0x0807 FFFF


   /* system memory 0x1FFF 0000 - 0x1FFF 77FF */
      .equ SYS_MEM, 0x1FFFF000
      .equ SYS_MEM_SIZE, 0x77FF 

   /* OTP memory 0x1FFF 7800 - 0x1FFF 7A0F */
      .equ OTP_MEM, 0x1FFF7800
      .equ OTP_SIZE, 0x210 

   /* option memory 0x1FFF C000 - 0x1FFF C00F */
      .equ OPTION, 0x1FFFC000   
      .equ OPT_SIZE, 16


   /* peripherals base address */
      .equ PER_BASE_ADR,  0x40000000
   /* PERIPHERALS bit band alias */
      .equ PER_BIT_ALIAS, 0x42000000 


    /* RCC registers address */
    .equ RCC_BASE_ADR, 0x40023800
    /* RCC registers offset */
    .equ RCC_CR, 0
    .equ RCC_PLLCFGR,0X4
    .equ RCC_CFGR, 0X8
    .equ RCC_CIR, 0XC
    .equ RCC_AHB1RSTR, 0X10
    .equ RCC_AHB2RSTR, 0X14
    .equ RCC_APB1RSTR, 0x20
    .equ RCC_APB2RSTR, 0X24
    .equ RCC_AHB1ENR, 0X30
    .equ RCC_AHB2ENR, 0X34 
    .equ RCC_APB1ENR, 0X40
    .equ RCC_APB2ENR, 0X44
    .equ RCC_AHB1LPENR,0X50
    .equ RCC_AHB2LPENR,0X54
    .equ RCC_APB1LPENR,0X60
    .equ RCC_APB2LPENR,0X64
    .equ RCC_BDCR,0X70
    .equ RCC_CSR,0X74
    .equ RCC_SSCGR,0X80
    .equ RCC_PLLI2SCFGR,0X84
    .equ RCC_DCKCFGR, 0X8C 

    /* FLASH registers address */
    .equ FLASH_BASE_ADR, 0x40023C00
    /* FLASH registers offset */
    .equ FLASH_ACR, 0
    .equ FLASH_KEYR, 4
    .equ FLASH_OPTKEYR, 8
    .equ FLASH_SR, 12
    .equ FLASH_CR, 16
    .equ FLASH_OPTCR, 20
    .equ RDPRT_KEY, 0x00A5
    .equ FLASH_KEY1, 0x45670123
    .equ FLASH_KEY2, 0xCDEF89AB
    .equ OPTKEY1, 0x08192A3B
    .equ OPTKEY2, 0x4C5D6E7F

    /* GPIOx base address */
    .equ GPIOA_BASE_ADR, 0x40020000
    .equ GPIOB_BASE_ADR, 0x40020400
    .equ GPIOC_BASE_ADR, 0x40020800
    .equ GPIOD_BASE_ADR, 0x40020C00
    .equ GPIOE_BASE_ADR, 0x40021000
    .equ GPIOH_BASE_ADR, 0x40021C00

    /* gpiox registers offset from base address */
    .equ GPIO_MODER, 0
    .equ GPIO_OTYPER, 4
    .equ GPIO_OSPEEDR, 8
    .equ GPIO_PUPDR, 12
    .equ GPIO_IDR, 16
    .equ GPIO_ODR, 20
    .equ GPIO_BSRR, 24 
    .equ GPIO_LCKR, 28
    .equ GPIO_AFRL, 32
    .equ GPIO_AFRH, 36
    
   /* GPIO mode and type */
   .equ INP,(0) // input mode 
   .equ GPO,(1)   // general purpose output
   .equ AFO,(2)   // alternate fucntion 
   .equ ANA,(3)   // analog mode 
   .equ PP,(0)    // push pull output 
   .equ OD,(1)    // open drain output 
   // output, low nibble mode, high nibble type 
   .equ OUTPUT_PP,(PP<<4)+GPO 
   .equ OUTPUT_OD,(OD<<4)+GPO 
   .equ OUTPUT_AFPP,(PP<<4)+AFO
   .equ OUTPUT_AFOD,(OD<<4)+AFO 
   // input high nibble pull mode, low input type  
   .equ FLOAT,(0)
   .equ PULLUP,(1)
   .equ PULLDOWN,(2)
   .equ INPUT_ANA,(FLOAT<<4)+ANA     
   .equ INPUT_FLOAT,(FLOAT<<4)+INP
   .equ INPUT_PD,(PULLDOWN<<4)+INP
   .equ INPUT_PU,(PULLUP<<4)+INP 

    /* USART1 registers */
    .equ USART1_BASE_ADR, 0x40011000
    /* USARTx registers offset */
    .equ USART_SR, 0
    .equ USART_DR,4
    .equ USART_BRR,8
    .equ USART_CR1,12
    .equ USART_CR2,16
    .equ USART_CR3,20
    .equ USART_GTPR,24

   /* systick */
    .equ STK_BASE_ADR, 0xE000E010
    /* registers offset */
    .equ STK_CTL, 0
    .equ STK_LOAD, 4
    .equ STK_VAL, 8
    .equ STK_CALIB, 12

   /* system control block */
   .equ SCB_BASE_ADR, 0xE000ED00
   /* registers offset */
   .equ SCB_CPUID, 0
   .equ SCB_ICSR, 0x4 
   .equ SCB_VTOR, 0x8
   .equ SCB_AIRCR, 0xc
   .equ SCB_SCR, 0x10
   .equ SCB_CCR, 0x14
   .equ SCB_SHPR1,0x18
   .equ SCB_SHPR2,0x1c
   .equ SCB_SHPR3,0x20
   .equ SCB_SHCSR,0x24
   .equ SCB_CFSR,0x28
   .equ SCB_MMSR,0x28
   .equ SCB_BFSR,0x29
   .equ SCB_UFSR,0x2a
   .equ SCB_HFSR,0x2c
   .equ SCB_MMAR,0x34
   .equ SCB_BFAR,0x38
   .equ SCB_AFSR,0x3c
   // key to to write in SCB_AIRCR 
   .equ SCB_VECTKEY,0x5fa 
   
   /* NVIC block */
   .equ NVIC_BASE_ADR, 0xE000E000
   .equ NVIC_ISER0, 0x100
   .equ NVIC_ISER1, 0x104
   .equ NVIC_ISER2, 0x108
   .equ NVIC_ISER3, 0x10c
   .equ NVIC_ISER4, 0x110
   .equ NVIC_ISER5, 0x114
   .equ NVIC_ISER6, 0x118
   .equ NVIC_ISER7, 0x11c
   .equ NVIC_ICER0, 0x180
   .equ NVIC_ICER1, 0x184 
   .equ NVIC_ICER2, 0x188 
   .equ NVIC_ICER3, 0x18C 
   .equ NVIC_ICER4, 0x190 
   .equ NVIC_ICER5, 0x194 
   .equ NVIC_ICER6, 0x198 
   .equ NVIC_ICER7, 0x19C 
   .equ NVIC_ISPR0, 0x200
   .equ NVIC_ISPR1, 0x204
   .equ NVIC_ISPR2, 0x208 
   .equ NVIC_ISPR3, 0x20c 
   .equ NVIC_ISPR4, 0x210 
   .equ NVIC_ISPR5, 0x214 
   .equ NVIC_ISPR6, 0x218 
   .equ NVIC_ISPR7, 0x21c 
   .equ NVIC_ICPR0, 0x280
   .equ NVIC_ICPR1, 0x284
   .equ NVIC_ICPR2, 0x288
   .equ NVIC_ICPR3, 0x28c
   .equ NVIC_ICPR4, 0x290
   .equ NVIC_ICPR5, 0x294
   .equ NVIC_ICPR6, 0x298
   .equ NVIC_ICPR7, 0x29c
   .equ NVIC_IABR0, 0x300
   .equ NVIC_IABR1, 0x304
   .equ NVIC_IABR2, 0x308
   .equ NVIC_IABR3, 0x30c
   .equ NVIC_IABR4, 0x310
   .equ NVIC_IABR5, 0x314
   .equ NVIC_IABR6, 0x318
   .equ NVIC_IABR7, 0x31c
/*  NVIC_IPR0 - NVIC_IPR59 */
   .equ NVIC_IPR_BASE, 0xE000E400 

/*  IRQ number */
   .equ NMI_IRQ, (-14) // non maskable
   .equ HF_IRQ, (-13)  // hard fault
   .equ MM_IRQ, (-12)  // memory Management
   .equ BF_IRQ, (-11)  // bus fault 
   .equ UF_IRQ, (-10)  // usage fault 
   .equ SVC_IRQ, (-5)  // service call 
   .equ DM_IRQ, (-4)  // debug monitor
   .equ PSV_IRQ, (-2) // pending service 
   .equ STCK_IRQ, (-1) // systick 
   .equ WWDG_IRQ, (0) // window watchdog 
   .equ EXTI16_IRQ, (1) // external interrupt line 16
   .equ EXTI21_IRQ, (2) // external interrupt line 21
   .equ EXTI22_IRQ, (3) // external interrupt line 22
   .equ FLASH_IRQ, (4) // flash global 
   .equ RCC_IRQ, (5)  // real time clock 
   .equ EXTI0_IRQ, (6) // 
   .equ EXTI1_IRQ, (7)
   .equ EXTI2_IRQ, (8)
   .equ EXTI3_IRQ, (9)
   .equ EXTI4_IRQ, (10)
   .equ DMA1S0_IRQ, (11) // DMA1 stream 0 
   .equ DMA1S1_IRQ, (12)
   .equ DMA1S2_IRQ, (13)
   .equ DMA1S3_IRQ, (14)
   .equ DMA1S4_IRQ, (15)
   .equ DMA1S5_IRQ, (16)
   .equ DMA1S6_IRQ, (17)
   .equ ADC_IRQ, (18)
   .equ EXTI9_5_IRQ, (23)
   .equ TIM1BRK_IRQ, (24) // TIMER1 BREAK 
   .equ TIM1UP_IRQ, (25) // TIMER1 Update
   .equ TIM1TRG_IRQ, (26) // TIMER1 trigger & commutation 
   .equ TIM1CC_IRQ, (27) // TIMER1 capture compare 
   .equ TIM2_IRQ, (28) // TIMER2 global 
   .equ TIM3_IRQ, (29) // TIMER3  global 
   .equ TIM4_IRQ, (30) // TIMER4 global
   .equ I2C1EV_IRQ, (31) // i2c1 event 
   .equ I2C1ER_IRQ, (32) // i2c1 error 
   .equ I2C2EV_IRQ, (33) // i2c2 event 
   .equ I2C2ER_IRQ, (34) // i2c2 error 
   .equ SPI1_IRQ, (35)  // SPI1 global 
   .equ SPI2_IRQ, (36)  // SPI2 global
   .equ USART1_IRQ, (37) // USART1 global
   .equ USART2_IRQ, (38) // USART2 global
   .equ EXTI15_10_IRQ, (40) // external interrupt lines 10,15
   .equ EXTI17_IRQ, (41)
   .equ EXTI18_IRQ, (42) // exti and OTG_FS_WKUP
   .equ DMA1S7_IRQ, (47) // DMA1 stream 7
   .equ SDIO_IRQ, (49) // SDIO global
   .equ TIM5_IRQ, (50) // TIMER5 global 
   .equ SPI3_IRQ, (51)
   .equ DMA2S0_IRQ, (56) // DMA2 stream 0 
   .equ DMA2S1_IRQ, (57) 
   .equ DMAS2_IRQ, (58)
   .equ DMAS3_IRQ, (59)
   .equ DMAS4_IRQ, (60)
   .equ OTG_FS_IRQ, (67)
   .equ DMA2S5_IRQ, (68)
   .equ DMA2S6_IRQ, (69)
   .equ DMA2S7_IRQ, (70)
   .equ USART6_IRQ, (71)
   .equ I2C3EV_IRQ, (72)
   .equ I2C3ER_IRQ, (73)
   .equ FPU_IRQ, (81) // FPU global
   .equ SPI4_IRQ, (84)
   .equ SPI5_IRQ, (85)
   

/* TIMERS registers */
.equ TIM1_BASE_ADR,0x40010000
.equ TIM9_BASE_ADR,0x40010400
.equ TIM10_BASE_ADR,0x40010800
.equ TIM11_BASE_ADR,0x40010C00

.equ TIM2_BASE_ADR,0x40000000
.equ TIM3_BASE_ADR,0x40000400
.equ TIM4_BASE_ADR,0x40000800
.equ TIM5_BASE_ADR,0x40000C00

/* TIMER1 */
.equ TIM1_RCR,48 
.equ TIM1_BDTR,68 

/* TIMER2..TIMER5 */
.equ TIM_CR1,0
.equ TIM_CR2,4
.equ TIM_SMCR,8
.equ TIM_DIER,12
.equ TIM_SR,16
.equ TIM_EGR,20
.equ TIM_CCMR1,24
.equ TIM_CCMR2,28
.equ TIM_CCER,32
.equ TIM_CNT,36
.equ TIM_PSC,40
.equ TIM_ARR,44
.equ TIM_CCR1,52
.equ TIM_CCR2,56
.equ TIM_CCR3,60
.equ TIM_CCR4,64
.equ TIM_DCR,72
.equ TIM_DMAR,76
.equ TIM2_OR,80
.equ TIM5_OR,80 

/* SYSCFG registers */
.equ SYSCFG_BASE_ADR, 0x40013800

.equ SYSCFG_MEMRMP,0
.equ SYSCFG_PMC,4
.equ SYSCFG_EXTICR1,8
.equ SYSCFG_EXTICR2,12
.equ SYSCFG_EXTICR3,16
.equ SYSCFG_EXTICR4,20
.equ SYSCFG_CMPCR,32

/* EXTI registers */
.equ EXTI_BASE_ADR, 0x40013C00

.equ EXTI_IMR,0
.equ EXTI_EMR,4
.equ EXTI_RTSR,8
.equ EXTI_FTSR,12
.equ EXTI_SWIER,16
.equ EXTI_PR,20

