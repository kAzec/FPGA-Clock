#ifndef __KERNEL__
#define __KERNEL__
#endif
#ifndef MODULE
#define MODULE
#endif
     
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/ioport.h>
#include <linux/io.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/spinlock_types.h>
#include <linux/time.h>
#include <asm/io.h>

#define CLOCK_BASE 0x233
#define CLOCK_PAGE_SIZE PAGE_SIZE
#define CLOCK_INT_NUM 11

static DEFINE_SPINLOCK(interrupt_flag_lock);

static uint8_t state;

static irqreturn_t fpga_clock_interrupt(int irq, void *dev_id)
{
    if (irq != CLOCK_INT_NUM)
        return IRQ_NONE;

    /** Set peripherals's time to the time of system **/
    struct timeval time;
    struct tm tm;
    unsigned long local_time;

    do_gettimeofday(&time);
    local_time = (u32)(time.tv_sec - (sys_tz.tz_minuteswest * 60));
    time_to_tm(local_time, &tm);

    uint8_t hour, min, sec, data;

    hour  = (uint8_t)tm.tm_hour;
    min   = (uint8_t)tm.tm_min;
    sec   = (uint8_t)tm.tm_sec;

    spin_lock(&interrupt_flag_lock);

    ioperm(CLOCK_BASE, 1, 1);
    outb(0x80 + hour, CLOCK_BASE);
    outb(0xA0 + min,  CLOCK_BASE);
    outb(0xC0 + sec,  CLOCK_BASE);

    spin_unlock(&interrupt_flag_lock);

    return IRQ_HANDLED;
}

static struct device_driver fpga_clock_driver = {
    .name = "fpga_clock",
    .bus = &platform_bus_type,
};

static ssize_t fpga_clock_show(struct device_driver *drv, char *buf)
{
    spin_lock(&interrupt_flag_lock);

    ioperm(CLOCK_BASE, 1, 1);
    outb(0x00, CLOCK_BASE);
    uint8_t hour = inb(CLOCK_BASE);

    outb(0x20, CLOCK_BASE);
    uint8_t min = inb(CLOCK_BASE);

    outb(0x40, CLOCK_BASE);
    uint8_t sec = inb(CLOCK_BASE);

    spin_unlock(&interrupt_flag_lock);

    buf[0] = hour;
    buf[1] = min;
    buf[2] = sec;

    return 1;
}

static ssize_t fpga_clock_store(struct device_driver *drv,
        const char *buf, size_t count)
{
    return -EROFS;
}

static DRIVER_ATTR(fpga_clock, S_IRUSR, fpga_clock_show, fpga_clock_store);

static int __init fpga_clock_init(void)
{
    int ret;
    struct resource *res;

    ret = driver_register(&fpga_clock_driver);
    if (ret < 0)
        goto fail_driver_register;

    ret = driver_create_file(&fpga_clock_driver,
            &driver_attr_fpga_clock);
    if (ret < 0)
        goto fail_create_file;

    // res = request_mem_region(CLOCK_BASE, CLOCK_SIZE, "fpga_clock");
    // if (res == NULL) {
    //     ret = -EBUSY;
    //     goto fail_request_mem;
    // }

    // fpga_clock_mem = ioremap(CLOCK_BASE, CLOCK_SIZE);
    // if (fpga_clock_mem == NULL) {
    //     ret = -EFAULT;
    //     goto fail_ioremap;
    // }

    ret = request_irq(CLOCK_INT_NUM, fpga_clock_interrupt,
            0, "fpga_clock", NULL);
    if (ret < 0)
        goto fail_request_irq;

    return 0;

fail_request_irq:
    printk(KERN_ERR "[CLOCK]: IRQ request failed!");
//     iounmap(fpga_clock_mem);
// fail_ioremap:
//     release_mem_region(CLOCK_BASE, CLOCK_SIZE);
// fail_request_mem:
fail_create_file:
    printk(KERN_ERR "[CLOCK]: File creation failed!");
    driver_remove_file(&fpga_clock_driver, &driver_attr_fpga_clock);
    driver_unregister(&fpga_clock_driver);
fail_driver_register:
    printk(KERN_ERR "[CLOCK]: Driver registration failed!");
    return ret;
}

static void __exit fpga_clock_exit(void)
{
    free_irq(CLOCK_INT_NUM, NULL);
    // iounmap(fpga_clock_mem);
    // release_mem_region(CLOCK_BASE, CLOCK_SIZE);
    driver_remove_file(&fpga_clock_driver, &driver_attr_fpga_clock);
    driver_unregister(&fpga_clock_driver);
}

MODULE_LICENSE("Dual MIT/GPL");

module_init(fpga_clock_init);
module_exit(fpga_clock_exit);