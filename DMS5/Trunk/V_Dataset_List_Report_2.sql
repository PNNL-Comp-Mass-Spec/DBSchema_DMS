/****** Object:  View [dbo].[V_Dataset_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_List_Report_2
AS
SELECT     DS.Dataset_ID AS ID, DS.Dataset_Num AS Dataset, Exp.Experiment_Num AS Experiment, C.Campaign_Num AS Campaign, DSN.DSS_name AS State, 
                      InstName.IN_name AS Instrument, DS.DS_created AS Created, DS.DS_comment AS Comment, DSRating.DRN_name AS Rating, 
                      DTN.DST_Name AS Type, DS.DS_Oper_PRN AS Operator, DFP.Dataset_Folder_Path AS [Dataset Folder Path], 
                      DFP.Archive_Folder_Path AS [Archive Folder Path], ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start) AS [Acq Start], ISNULL(DS.Acq_Time_End, 
                      RRH.RDS_Run_Finish) AS [Acq. End], DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start), ISNULL(DS.Acq_Time_End, 
                      RRH.RDS_Run_Finish)) AS [Acq Length], DS.Scan_Count AS [Scan Count], LC.SC_Column_Number AS [LC Column], 
                      DS.DS_sec_sep AS [Separation Type], RRH.RDS_Blocking_Factor AS [Blocking Factor], RRH.RDS_Block AS Block, 
                      RRH.RDS_Run_Order AS [Run Order], RRH.ID AS Request, DASN.DASN_StateName AS [Archive State]
FROM         dbo.T_DatasetArchiveStateName AS DASN INNER JOIN
                      dbo.T_Dataset_Archive AS DSA ON DASN.DASN_StateID = DSA.AS_state_ID RIGHT OUTER JOIN
                      dbo.T_DatasetStateName AS DSN INNER JOIN
                      dbo.T_Dataset AS DS ON DSN.Dataset_state_ID = DS.DS_state_ID INNER JOIN
                      dbo.T_DatasetTypeName AS DTN ON DS.DS_type_ID = DTN.DST_Type_ID INNER JOIN
                      dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
                      dbo.T_DatasetRatingName AS DSRating ON DS.DS_rating = DSRating.DRN_state_ID INNER JOIN
                      dbo.T_Experiments AS Exp ON DS.Exp_ID = Exp.Exp_ID INNER JOIN
                      dbo.T_Campaign AS C ON Exp.EX_campaign_ID = C.Campaign_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths AS DFP ON DS.Dataset_ID = DFP.Dataset_ID INNER JOIN
                      dbo.T_LC_Column AS LC ON DS.DS_LC_column_ID = LC.ID ON DSA.AS_Dataset_ID = DS.Dataset_ID LEFT OUTER JOIN
                      dbo.T_Requested_Run AS RRH ON DS.Dataset_ID = RRH.DatasetID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
