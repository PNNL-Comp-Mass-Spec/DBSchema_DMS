/****** Object:  View [dbo].[V_Charge_Code_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_List_Report]
AS
SELECT CC.charge_code,
       CCA.Activation_State_Name AS state,
       CC.WBS_Title AS wbs,
       CC.Charge_Code_Title AS title,
       CC.SubAccount_Title AS sub_account,
       CC.Usage_SamplePrep AS usage_sample_prep,
       CC.Usage_RequestedRun AS usage_requested_run,
       ISNULL(DMSUser.u_prn, 'D' + CC.Resp_PRN) AS owner_prn,
       DMSUser.U_Name AS owner_name,
       CC.setup_date,
       SortKey AS sort_key,
       CC.Activation_State AS activation_state
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code


GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_List_Report] TO [DDL_Viewer] AS [dbo]
GO
