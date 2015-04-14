  496  sudo -s

  497  source ../netfpga10g/bashrc_addon_NetFPGA_10G 

  498  ../netfpga10g/tools/scripts/impact_run.sh ../netfpga10g/contrib-projects/backup/teststream/hw/implementation/system.bit ../netfpga10g/projects/production_test/bitfiles/cpld.jed 

  Kiem tra PCI 
  lspci | egrep "Xilinx"
  Neu khong thay thi reboot

  499  reboot

  500  source ../netfpga10g/bashrc_addon_NetFPGA_10G 

  501  ../netfpga10g/tools/scripts/impact_run.sh ../netfpga10g/contrib-projects/backup/teststream/hw/system.bit

  502  ../netfpga10g/tools/scripts/impact_run.sh ../netfpga10g/contrib-projects/backup/teststream/hw/system.bit

  503  ../netfpga10g/tools/scripts/impact_run.sh ../netfpga10g/contrib-projects/backup/teststream/hw/implementation/system.bit





test sau khi nop file bit

  504  ifconfig -a

  505  ifconfig nf0 up

  506  ./hrav

  507  vi hrav.c

  508  gcc -o hrav hrav.c

  509  ./hrav

  510  history > runstring.txt


