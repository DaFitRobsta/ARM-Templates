```powershell
Get-AzSqlServerServiceObjective -Location westus2

ServiceObjectiveName SkuName       Edition          Family Capacity CapacityUnit Enabled
-------------------- -------       -------          ------ -------- ------------ -------
System               System        System                  0        DTU          False
System0              System        System                  0        DTU          False
System1              System        System                  0        DTU          False
System2              System        System                  0        DTU          False
System3              System        System                  0        DTU          False
System4              System        System                  0        DTU          False
System2L             System        System                  0        DTU          False
System3L             System        System                  0        DTU          False
System4L             System        System                  0        DTU          False
Free                 Free          Free                    5        DTU          True
Basic                Basic         Basic                   5        DTU          True
S0                   Standard      Standard                10       DTU          True
S1                   Standard      Standard                20       DTU          True
S2                   Standard      Standard                50       DTU          True
S3                   Standard      Standard                100      DTU          True
S4                   Standard      Standard                200      DTU          True
S6                   Standard      Standard                400      DTU          True
S7                   Standard      Standard                800      DTU          True
S9                   Standard      Standard                1600     DTU          True
S12                  Standard      Standard                3000     DTU          True
P1                   Premium       Premium                 125      DTU          True
P2                   Premium       Premium                 250      DTU          True
P4                   Premium       Premium                 500      DTU          True
P6                   Premium       Premium                 1000     DTU          True
P11                  Premium       Premium                 1750     DTU          True
P15                  Premium       Premium                 4000     DTU          True
DW100c               DataWarehouse DataWarehouse           900      DTU          True
DW200c               DataWarehouse DataWarehouse           1800     DTU          True
DW300c               DataWarehouse DataWarehouse           2700     DTU          True
DW400c               DataWarehouse DataWarehouse           3600     DTU          True
DW500c               DataWarehouse DataWarehouse           4500     DTU          True
DW1000c              DataWarehouse DataWarehouse           9000     DTU          True
DW1500c              DataWarehouse DataWarehouse           13500    DTU          True
DW2000c              DataWarehouse DataWarehouse           18000    DTU          True
DW2500c              DataWarehouse DataWarehouse           22500    DTU          True
DW3000c              DataWarehouse DataWarehouse           27000    DTU          True
DW5000c              DataWarehouse DataWarehouse           45000    DTU          True
DW6000c              DataWarehouse DataWarehouse           54000    DTU          True
DW7500c              DataWarehouse DataWarehouse           67500    DTU          True
DW10000c             DataWarehouse DataWarehouse           90000    DTU          True
DW15000c             DataWarehouse DataWarehouse           135000   DTU          True
DW30000c             DataWarehouse DataWarehouse           270000   DTU          True
DS100                Stretch       Stretch                 750      DTU          True
DS200                Stretch       Stretch                 1500     DTU          True
DS300                Stretch       Stretch                 2250     DTU          True
DS400                Stretch       Stretch                 3000     DTU          True
DS500                Stretch       Stretch                 3750     DTU          True
DS600                Stretch       Stretch                 4500     DTU          True
DS1000               Stretch       Stretch                 7500     DTU          True
DS1200               Stretch       Stretch                 9000     DTU          True
DS1500               Stretch       Stretch                 11250    DTU          True
DS2000               Stretch       Stretch                 15000    DTU          True
GP_S_Gen5_1          GP_S_Gen5     GeneralPurpose   Gen5   1        VCores       True
GP_Gen5_2            GP_Gen5       GeneralPurpose   Gen5   2        VCores       True
GP_S_Gen5_2          GP_S_Gen5     GeneralPurpose   Gen5   2        VCores       True
GP_Gen5_4            GP_Gen5       GeneralPurpose   Gen5   4        VCores       True
GP_S_Gen5_4          GP_S_Gen5     GeneralPurpose   Gen5   4        VCores       True
GP_Gen5_6            GP_Gen5       GeneralPurpose   Gen5   6        VCores       True
GP_S_Gen5_6          GP_S_Gen5     GeneralPurpose   Gen5   6        VCores       True
GP_Gen5_8            GP_Gen5       GeneralPurpose   Gen5   8        VCores       True
GP_S_Gen5_8          GP_S_Gen5     GeneralPurpose   Gen5   8        VCores       True
GP_Fsv2_8            GP_Fsv2       GeneralPurpose   Fsv2   8        VCores       True
GP_Gen5_10           GP_Gen5       GeneralPurpose   Gen5   10       VCores       True
GP_S_Gen5_10         GP_S_Gen5     GeneralPurpose   Gen5   10       VCores       True
GP_Fsv2_10           GP_Fsv2       GeneralPurpose   Fsv2   10       VCores       True
GP_Gen5_12           GP_Gen5       GeneralPurpose   Gen5   12       VCores       True
GP_S_Gen5_12         GP_S_Gen5     GeneralPurpose   Gen5   12       VCores       True
GP_Fsv2_12           GP_Fsv2       GeneralPurpose   Fsv2   12       VCores       True
GP_Gen5_14           GP_Gen5       GeneralPurpose   Gen5   14       VCores       True
GP_S_Gen5_14         GP_S_Gen5     GeneralPurpose   Gen5   14       VCores       True
GP_Fsv2_14           GP_Fsv2       GeneralPurpose   Fsv2   14       VCores       True
GP_Gen5_16           GP_Gen5       GeneralPurpose   Gen5   16       VCores       True
GP_S_Gen5_16         GP_S_Gen5     GeneralPurpose   Gen5   16       VCores       True
GP_Fsv2_16           GP_Fsv2       GeneralPurpose   Fsv2   16       VCores       True
GP_Gen5_18           GP_Gen5       GeneralPurpose   Gen5   18       VCores       True
GP_S_Gen5_18         GP_S_Gen5     GeneralPurpose   Gen5   18       VCores       True
GP_Fsv2_18           GP_Fsv2       GeneralPurpose   Fsv2   18       VCores       True
GP_Gen5_20           GP_Gen5       GeneralPurpose   Gen5   20       VCores       True
GP_S_Gen5_20         GP_S_Gen5     GeneralPurpose   Gen5   20       VCores       True
GP_Fsv2_20           GP_Fsv2       GeneralPurpose   Fsv2   20       VCores       True
GP_Gen5_24           GP_Gen5       GeneralPurpose   Gen5   24       VCores       True
GP_S_Gen5_24         GP_S_Gen5     GeneralPurpose   Gen5   24       VCores       True
GP_Fsv2_24           GP_Fsv2       GeneralPurpose   Fsv2   24       VCores       True
GP_Gen5_32           GP_Gen5       GeneralPurpose   Gen5   32       VCores       True
GP_S_Gen5_32         GP_S_Gen5     GeneralPurpose   Gen5   32       VCores       True
GP_Fsv2_32           GP_Fsv2       GeneralPurpose   Fsv2   32       VCores       True
GP_Fsv2_36           GP_Fsv2       GeneralPurpose   Fsv2   36       VCores       True
GP_Gen5_40           GP_Gen5       GeneralPurpose   Gen5   40       VCores       True
GP_S_Gen5_40         GP_S_Gen5     GeneralPurpose   Gen5   40       VCores       True
GP_Fsv2_72           GP_Fsv2       GeneralPurpose   Fsv2   72       VCores       True
GP_Gen5_80           GP_Gen5       GeneralPurpose   Gen5   80       VCores       True
BC_Gen5_2            BC_Gen5       BusinessCritical Gen5   2        VCores       True
BC_Gen5_4            BC_Gen5       BusinessCritical Gen5   4        VCores       True
BC_Gen5_6            BC_Gen5       BusinessCritical Gen5   6        VCores       True
BC_Gen5_8            BC_Gen5       BusinessCritical Gen5   8        VCores       True
BC_M_8               BC_M          BusinessCritical M      8        VCores       False
BC_Gen5_10           BC_Gen5       BusinessCritical Gen5   10       VCores       True
BC_M_10              BC_M          BusinessCritical M      10       VCores       False
BC_Gen5_12           BC_Gen5       BusinessCritical Gen5   12       VCores       True
BC_M_12              BC_M          BusinessCritical M      12       VCores       False
BC_Gen5_14           BC_Gen5       BusinessCritical Gen5   14       VCores       True
BC_M_14              BC_M          BusinessCritical M      14       VCores       False
BC_Gen5_16           BC_Gen5       BusinessCritical Gen5   16       VCores       True
BC_M_16              BC_M          BusinessCritical M      16       VCores       False
BC_Gen5_18           BC_Gen5       BusinessCritical Gen5   18       VCores       True
BC_M_18              BC_M          BusinessCritical M      18       VCores       False
BC_Gen5_20           BC_Gen5       BusinessCritical Gen5   20       VCores       True
BC_M_20              BC_M          BusinessCritical M      20       VCores       False
BC_Gen5_24           BC_Gen5       BusinessCritical Gen5   24       VCores       True
BC_M_24              BC_M          BusinessCritical M      24       VCores       False
BC_Gen5_32           BC_Gen5       BusinessCritical Gen5   32       VCores       True
BC_M_32              BC_M          BusinessCritical M      32       VCores       False
BC_Gen5_40           BC_Gen5       BusinessCritical Gen5   40       VCores       True
BC_M_64              BC_M          BusinessCritical M      64       VCores       False
BC_Gen5_80           BC_Gen5       BusinessCritical Gen5   80       VCores       True
BC_M_128             BC_M          BusinessCritical M      128      VCores       False
HS_Gen5_2            HS_Gen5       Hyperscale       Gen5   2        VCores       True
HS_Gen5_4            HS_Gen5       Hyperscale       Gen5   4        VCores       True
HS_Gen5_6            HS_Gen5       Hyperscale       Gen5   6        VCores       True
HS_Gen5_8            HS_Gen5       Hyperscale       Gen5   8        VCores       True
HS_Gen5_10           HS_Gen5       Hyperscale       Gen5   10       VCores       True
HS_Gen5_12           HS_Gen5       Hyperscale       Gen5   12       VCores       True
HS_Gen5_14           HS_Gen5       Hyperscale       Gen5   14       VCores       True
HS_Gen5_16           HS_Gen5       Hyperscale       Gen5   16       VCores       True
HS_Gen5_18           HS_Gen5       Hyperscale       Gen5   18       VCores       True
HS_Gen5_20           HS_Gen5       Hyperscale       Gen5   20       VCores       True
HS_Gen5_24           HS_Gen5       Hyperscale       Gen5   24       VCores       True
HS_S_8IM_24          HS_S_8IM      Hyperscale       8IH    24       VCores       True
HS_8IM_24            HS_8IM        Hyperscale       8IH    24       VCores       True
HS_Gen5_32           HS_Gen5       Hyperscale       Gen5   32       VCores       True
HS_Gen5_40           HS_Gen5       Hyperscale       Gen5   40       VCores       True
HS_8IM_48            HS_8IM        Hyperscale       8IH    48       VCores       True
HS_Gen5_80           HS_Gen5       Hyperscale       Gen5   80       VCores       True
HS_S_8IM_80          HS_S_8IM      Hyperscale       8IH    80       VCores       True
HS_8IM_80            HS_8IM        Hyperscale       8IH    80       VCores       True
```