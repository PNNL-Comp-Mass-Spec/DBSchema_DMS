/****** Object:  View [dbo].[V_Charge_Code_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_Export]
AS
SELECT CC.Charge_Code,                       -- aka [Work Package]
       CCA.Activation_State_Name AS State,
       CC.SubAccount_Title AS Sub_Account,
       CC.WBS_Title AS Work_Breakdown_Structure,
       CC.Charge_Code_Title AS Title,
       CC.Usage_SamplePrep AS Usage_Sample_Prep,
       CC.Usage_RequestedRun AS Usage_Requested_Run,
       ISNULL(DMSUser.Username, 'D' + CC.Resp_PRN) AS Owner_Username,
       DMSUser.Name AS Owner_Name,
       CC.Setup_Date,
       CC.SortKey AS Sort_Key,
       -- The following are old column names, included for compatibility with older versions of Buzzard
       CC.SubAccount_Title AS SubAccount,
       CC.WBS_Title AS WorkBreakdownStructure,
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
