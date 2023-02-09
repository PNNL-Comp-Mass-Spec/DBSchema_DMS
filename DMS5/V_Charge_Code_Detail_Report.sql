/****** Object:  View [dbo].[V_Charge_Code_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_Detail_Report]
AS
SELECT CC.charge_code,
       ISNULL(CCA.activation_state_name, 'Invalid') AS state,
       CC.WBS_Title AS wbs,
       CC.Charge_Code_Title AS title,
       CC.SubAccount AS sub_account_id,
       CC.SubAccount_Title AS sub_account,
       CC.subaccount_effective_date AS sub_account_effective_date,
       CC.inactive_date_most_recent,
       CC.inactive_date,
       CC.SubAccount_Inactive_Date AS sub_account_inactive_date,
       CC.deactivated,
       CC.setup_date,
       CC.Usage_SamplePrep AS usage_sample_prep,
       CC.Usage_RequestedRun AS usage_requested_run,
       CC.resp_prn AS resp_username,
       CC.resp_hid,
       DMSUser.username AS owner_username,
       DMSUser.name AS owner_name,
       CC.auto_defined,
       CC.charge_code_state,
       CC.last_affected,
	   CCA.Activation_State AS wp_activation_state
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code

GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
