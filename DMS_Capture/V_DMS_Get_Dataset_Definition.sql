/****** Object:  View [dbo].[V_DMS_Get_Dataset_Definition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Get_Dataset_Definition]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       SPath.SP_machine_name AS Storage_Server_Name,
       TIN.IN_name AS Instrument_Name,
       TIN.IN_class AS Instrument_Class,
       TIN.IN_Max_Simultaneous_Captures AS Max_Simultaneous_Captures,
	   DS.Capture_Subfolder
FROM S_DMS_T_Dataset AS DS
     INNER JOIN S_DMS_T_Instrument_Name AS TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
     LEFT OUTER JOIN S_DMS_t_storage_path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID


GO
