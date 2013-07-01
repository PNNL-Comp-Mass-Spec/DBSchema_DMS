/****** Object:  View [dbo].[V_Charge_Code_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_Status]
AS
SELECT CC.Charge_Code,
       CC.Charge_Code_State,
       CCS.Charge_Code_State_Name,
       CC.Activation_State,
       CCA.Activation_State_Name
FROM T_Charge_Code CC
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON CC.Activation_State = CCA.Activation_State
     INNER JOIN T_Charge_Code_State CCS
       ON CC.Charge_Code_State = CCS.Charge_Code_State


GO
