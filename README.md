一个简易的 stm32 OS:</br>
1,SolarOS来自https://github.com/Solar914/SolarOS_STM32</br>
2,非常容易移植,移植方法是先建一个裸机工程并编译跑通,后加入SolarOS目录中的文件,并修改相应.c中的#include "stm32f7xx.h"为你的开发板的相应头文件,
并注释掉stm32fxxx_it.c中的PendSV_Handler()和SysTick_Handler()函数即可</br>
3,本程序在stm32f767zi-nucleo开发板上运行成功,运行时红绿蓝三个LED灯闪烁</br>