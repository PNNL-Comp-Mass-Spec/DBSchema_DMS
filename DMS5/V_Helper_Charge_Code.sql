/****** Object:  View [dbo].[V_Helper_Charge_Code] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Charge_Code]
AS
SELECT CC.Charge_Code,
       CC.WBS_Title AS WBS,
       CC.Charge_Code_Title AS Title,
       CC.SubAccount_Title AS SubAccount,
       CC.Usage_SamplePrep,
       CC.Usage_RequestedRun,
       ISNULL(DMSUser.U_PRN, 'D' + CC.Resp_PRN) AS Owner_PRN,
       DMSUser.U_Name AS Owner_Name,
       CC.Setup_Date,
       SortKey
FROM T_Charge_Code CC
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code
WHERE CC.Charge_Code_State > 0


GO
