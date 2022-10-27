/****** Object:  View [dbo].[V_Charge_Code_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_List_Report]
AS
SELECT CC.Charge_Code,
       CCA.Activation_State_Name AS State,
       CC.WBS_Title AS WBS,
       CC.Charge_Code_Title AS Title,
       CC.SubAccount_Title AS SubAccount,
       CC.Usage_SamplePrep AS Usage_Sample_Prep,
       CC.Usage_RequestedRun AS Usage_Requested_Run,
       ISNULL(DMSUser.U_PRN, 'D' + CC.Resp_PRN) AS Owner_PRN,
       DMSUser.U_Name AS Owner_Name,
       CC.Setup_Date,
       SortKey,
        CC.Activation_State AS #activation_state
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code


GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_List_Report] TO [DDL_Viewer] AS [dbo]
GO
