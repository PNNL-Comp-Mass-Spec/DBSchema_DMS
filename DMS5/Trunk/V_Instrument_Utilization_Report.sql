/****** Object:  View [dbo].[V_Instrument_Utilization_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Instrument_Utilization_Report
AS
SELECT     T_Instrument_Name.IN_name AS Instrument, T_Dataset.DS_instrument_name_ID AS Instrument_ID, T_Dataset.Dataset_Num AS Dataset, 
                      T_Dataset.Dataset_ID AS Dataset_ID, NULL AS Run_Start, T_Dataset.DS_created AS Run_Finish, T_Requested_Run_History.ID AS Request, 
                      T_Requested_Run_History.RDS_Oper_PRN AS Requester
FROM         T_Dataset INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_DatasetTypeName ON T_Dataset.DS_type_ID = T_DatasetTypeName.DST_Type_ID LEFT OUTER JOIN
                      T_Requested_Run_History ON T_Dataset.Dataset_ID = T_Requested_Run_History.DatasetID
WHERE     (T_Dataset.DS_state_ID = 3)

GO
