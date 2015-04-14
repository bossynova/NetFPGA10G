#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x35ec255d, "module_layout" },
	{ 0x1fedf0f4, "__request_region" },
	{ 0x2f35ab80, "cdev_del" },
	{ 0xcea0a119, "kmalloc_caches" },
	{ 0xf18242e1, "atomic64_set_cx8" },
	{ 0x12da5bb2, "__kmalloc" },
	{ 0xb2c831b6, "cdev_init" },
	{ 0xf9a482f9, "msleep" },
	{ 0xfc9c80e4, "mem_map" },
	{ 0x69a358a6, "iomem_resource" },
	{ 0xf82fd183, "skb_pad" },
	{ 0x93d085b2, "dev_set_drvdata" },
	{ 0x43a53735, "__alloc_workqueue_key" },
	{ 0x24d52bf2, "dma_set_mask" },
	{ 0xdeae679e, "pci_disable_device" },
	{ 0x6c5f5671, "device_destroy" },
	{ 0x33543801, "queue_work" },
	{ 0x91095cab, "x86_dma_fallback_dev" },
	{ 0x7485e15e, "unregister_chrdev_region" },
	{ 0xb7f55ecc, "atomic64_add_return_cx8" },
	{ 0xdb6a81c7, "__netdev_alloc_skb" },
	{ 0x435f447e, "pci_set_master" },
	{ 0xf97456ea, "_raw_spin_unlock_irqrestore" },
	{ 0x50eedeb8, "printk" },
	{ 0xf745cb16, "atomic64_sub_return_cx8" },
	{ 0xa6214375, "class_unregister" },
	{ 0x5933009c, "free_netdev" },
	{ 0xcc4d1bfb, "atomic64_read_cx8" },
	{ 0x2f287f0d, "copy_to_user" },
	{ 0x989da7fa, "register_netdev" },
	{ 0xb4390f9a, "mcount" },
	{ 0x5bce5c4a, "netif_receive_skb" },
	{ 0x16305289, "warn_slowpath_null" },
	{ 0x60781a70, "device_create" },
	{ 0xf1243fad, "dma_release_from_coherent" },
	{ 0x2072ee9b, "request_threaded_irq" },
	{ 0xd0e5ca65, "dev_kfree_skb_any" },
	{ 0x7087c350, "dma_alloc_from_coherent" },
	{ 0xebd5feb1, "cdev_add" },
	{ 0x42c8de35, "ioremap_nocache" },
	{ 0x3bd1b1f6, "msecs_to_jiffies" },
	{ 0xe97e420b, "kfree_skb" },
	{ 0xc7151517, "alloc_netdev_mqs" },
	{ 0x8c521e40, "eth_type_trans" },
	{ 0x7c61340c, "__release_region" },
	{ 0x44a8e76b, "pci_unregister_driver" },
	{ 0xe75ad2f4, "ether_setup" },
	{ 0x41ad0272, "kmem_cache_alloc_trace" },
	{ 0x21fb443e, "_raw_spin_lock_irqsave" },
	{ 0x762add85, "atomic64_inc_return_cx8" },
	{ 0x37a0cba, "kfree" },
	{ 0x411ae61c, "pci_disable_msi" },
	{ 0xedc03953, "iounmap" },
	{ 0xe7472ec, "__pci_register_driver" },
	{ 0x84b6f4af, "class_destroy" },
	{ 0x4b22f57a, "unregister_netdev" },
	{ 0xe2735d4f, "pci_enable_msi_block" },
	{ 0x49200c00, "__netif_schedule" },
	{ 0x2cdc50e8, "skb_put" },
	{ 0x9a756412, "pci_enable_device" },
	{ 0x362ef408, "_copy_from_user" },
	{ 0x32b91bd6, "__class_create" },
	{ 0xddffa24, "dev_get_drvdata" },
	{ 0x31944a28, "dma_ops" },
	{ 0x29537c9e, "alloc_chrdev_region" },
	{ 0xf20dabd8, "free_irq" },
	{ 0xa7cf6c2f, "atomic64_dec_return_cx8" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("pci:v000010EEd00004244sv*sd*bc*sc*i*");

MODULE_INFO(srcversion, "8034CB60CC51520B320411F");
