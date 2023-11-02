/****** Object:  View [dbo].[V_DMS_Dataset_LC_Instrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Dataset_LC_Instrument]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID AS Dataset_ID,
       LCC.Cart_Name AS LC_Cart_Name,
       TIN.IN_name AS LC_Instrument_Name,
       TIN.IN_class AS LC_Instrument_Class,
       TIN.IN_Group AS LC_Instrument_Group,
       TIN.IN_capture_method AS LC_Instrument_Capture_Method,
       TSP.SP_vol_name_server AS Source_Vol,
       TSP.SP_path AS Source_Path
FROM S_DMS_T_Dataset AS DS
     INNER JOIN S_DMS_T_Requested_Run AS RR 
       ON DS.Dataset_ID = RR.DatasetID
     INNER JOIN S_DMS_T_LC_Cart AS LCC 
       ON RR.RDS_Cart_ID = LCC.ID
     LEFT OUTER JOIN S_DMS_T_Instrument_Name AS TIN 
       ON LCC.Cart_Name = TIN.IN_name
     LEFT OUTER JOIN S_DMS_T_Storage_Path AS TSP
       ON TIN.IN_source_path_ID = TSP.SP_path_ID

GO
