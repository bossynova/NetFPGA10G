/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

#include "xsi.h"

struct XSI_INFO xsi_info;



int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    work_m_01673616876896105677_4151677459_init();
    work_m_12151298214354796559_0092728725_init();
    work_m_10293112072860237508_2484356840_init();
    xilinxcorelib_ver_m_06419288859600001517_1863797680_init();
    xilinxcorelib_ver_m_02693843609087607046_4015548717_init();
    xilinxcorelib_ver_m_09003160300769859152_0587908671_init();
    xilinxcorelib_ver_m_00752542628001252942_1026354600_init();
    work_m_18219643850453675774_2564069243_init();
    xilinxcorelib_ver_m_06419288859600001517_2853338241_init();
    xilinxcorelib_ver_m_02693843609087607046_1822223857_init();
    xilinxcorelib_ver_m_09003160300769859152_0800714690_init();
    xilinxcorelib_ver_m_00752542628001252942_1360385422_init();
    work_m_18219643850453675774_3702485497_init();
    work_m_14718534722680036545_2222020537_init();
    work_m_14439799017931948583_3403657398_init();
    work_m_05916918345074099601_4221868753_init();
    work_m_16541823861846354283_2073120511_init();


    xsi_register_tops("work_m_05916918345074099601_4221868753");
    xsi_register_tops("work_m_16541823861846354283_2073120511");


    return xsi_run_simulation(argc, argv);

}
