/****** Object:  View [dbo].[V_Find_User_Proposal_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Find_User_Proposal_Dataset
AS
SELECT     T_Requested_Run_History.RDS_EUS_Proposal_ID AS User_Proposal_ID, T_Dataset.Dataset_Num AS Dataset_Name, T_Dataset.Dataset_ID, 
                      T_Instrument_Name.IN_name AS Instrument_Name, T_Dataset.Acq_Time_Start AS Acquisition_Start, 
                      T_Dataset.Acq_Time_End AS Acquisition_End
FROM         T_Dataset INNER JOIN
                      T_Requested_Run_History ON T_Dataset.Dataset_ID = T_Requested_Run_History.DatasetID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID

GO
