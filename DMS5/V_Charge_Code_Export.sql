/****** Object:  View [dbo].[V_Charge_Code_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_Export]
AS
SELECT CC.Charge_Code,                       -- aka [Work Package]
       CCA.Activation_State_Name AS State,
       CC.SubAccount_Title AS SubAccount,
       CC.WBS_Title AS WorkBreakdownStructure,
       CC.Charge_Code_Title AS Title,
       CC.Usage_SamplePrep,
       CC.Usage_RequestedRun,
       ISNULL(DMSUser.U_PRN, 'D' + CC.Resp_PRN) AS Owner_PRN,
       DMSUser.U_Name AS Owner_Name,
       CC.Setup_Date,
       CC.SortKey
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code


GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_Export] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Charge_Code_Export] TO [DMS_LCMSNet_User] AS [dbo]
GO
