/****** Object:  View [dbo].[V_Find_User_Proposal_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_User_Proposal_Dataset
AS
SELECT dbo.T_Requested_Run_History.RDS_EUS_Proposal_ID AS User_Proposal_ID,
     dbo.T_Dataset.Dataset_Num AS Dataset_Name, 
    dbo.T_Dataset.Dataset_ID, 
    dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
    dbo.T_Dataset.Acq_Time_Start AS Acquisition_Start, 
    dbo.T_Dataset.Acq_Time_End AS Acquisition_End, 
    dbo.T_Dataset.Scan_Count
FROM dbo.T_Dataset INNER JOIN
    dbo.T_Requested_Run_History ON 
    dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID
     INNER JOIN
    dbo.T_Instrument_Name ON 
    dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID

GO
