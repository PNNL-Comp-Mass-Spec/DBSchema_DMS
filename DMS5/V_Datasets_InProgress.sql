/****** Object:  View [dbo].[V_Datasets_InProgress] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Datasets_InProgress
AS
SELECT T_Dataset.Dataset_Num, T_Dataset.DS_folder_name, 
   T_Dataset.Dataset_ID, T_Users.U_Name, 
   T_Dataset.DS_created, T_Dataset.DS_state_ID, 
   T_Instrument_Name.IN_name
FROM T_Dataset INNER JOIN
   T_Users ON 
   T_Dataset.DS_Oper_PRN = T_Users.U_PRN INNER JOIN
   T_Instrument_Name ON 
   T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE (T_Dataset.DS_state_ID = 2)
GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_InProgress] TO [PNL\D3M578] AS [dbo]
GO
