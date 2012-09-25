/****** Object:  View [dbo].[V_Dataset_QC_Metrics_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[V_Dataset_QC_Metrics_Detail_Report]
AS
SELECT InstName.IN_Group AS [Instrument Group],
       InstName.IN_name AS Instrument,
       DS.Acq_Time_Start,
       DQC.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       DQC.SMAQC_Job,
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name AS 'QC Metric Stats',
       /*
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_1A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_1B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_2A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_3B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_4A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_4B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/C_4C' AS 'Chromatography Plots',
       
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_1A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_1B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_2A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_2B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_3A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/DS_3B' AS 'Data Sampling Plots',
       
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_1A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_1B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_2, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_3A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_3B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/IS_3C' AS 'Ion Related Plots',
       
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_1, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_2A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_2B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_3A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_3B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_5A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_5B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_5C, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS1_5D' AS 'MS1 Plots',

       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_1, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_2, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_3, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_4A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_4B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_4C, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/MS2_4D' AS 'MS2 Plots',
       
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/P_1A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/P_1B, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/P_2A, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/P_2C, ' +
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name + '/P_3' AS 'Peptide ID Plots',
       */
       
       DQC.C_1A, DQC.C_1B, DQC.C_2A, DQC.C_2B, DQC.C_3A, DQC.C_3B, DQC.C_4A, DQC.C_4B, DQC.C_4C, 
       DQC.DS_1A, DQC.DS_1B, DQC.DS_2A, DQC.DS_2B, DQC.DS_3A, DQC.DS_3B, 
       DQC.IS_1A, DQC.IS_1B, DQC.IS_2, DQC.IS_3A, DQC.IS_3B, DQC.IS_3C, 
       DQC.MS1_1, DQC.MS1_2A, DQC.MS1_2B, DQC.MS1_3A, DQC.MS1_3B,
       DQC.MS1_5A, DQC.MS1_5B, DQC.MS1_5C, DQC.MS1_5D, 
       DQC.MS2_1, DQC.MS2_2, DQC.MS2_3, 
       DQC.MS2_4A, DQC.MS2_4B, DQC.MS2_4C, DQC.MS2_4D,
       DQC.P_1A, DQC.P_1B, DQC.P_2A, DQC.P_2B, DQC.P_2C, DQC.P_3,
       DQC.Last_Affected AS Metrics_Last_Affected
FROM T_Dataset_QC DQC
     INNER JOIN T_Dataset DS
       ON DQC.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN dbo.V_Dataset_Folder_Paths DFP
       ON DQC.Dataset_ID = DFP.Dataset_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
