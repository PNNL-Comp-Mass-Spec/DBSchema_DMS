/****** Object:  View [dbo].[V_Charge_Code_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Charge_Code_Detail_Report
AS
SELECT CC.Charge_Code,
       ISNULL(CCA.Activation_State_Name, 'Invalid') AS State,
       CC.WBS_Title AS WBS,
       CC.Charge_Code_Title AS Title,
       CC.SubAccount AS SubAccount_ID,
       CC.SubAccount_Title AS SubAccount,
       CC.SubAccount_Effective_Date,
       CC.Inactive_Date_Most_Recent,
       CC.Inactive_Date,
       CC.SubAccount_Inactive_Date,
       CC.Deactivated,
       CC.Setup_Date,
       CC.Usage_SamplePrep,
       CC.Usage_RequestedRun,
       CC.Resp_PRN,
       CC.Resp_HID,
       DMSUser.U_PRN AS Owner_PRN,
       DMSUser.U_Name AS Owner_Name,
       CC.Auto_Defined,
       CC.Charge_Code_State,
       CC.Last_Affected,
	   CCA.Activation_State AS #WPActivationState
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map DMSUser
       ON CC.Charge_Code = DMSUser.Charge_Code

GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
