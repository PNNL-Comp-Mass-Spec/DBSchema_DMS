/****** Object:  View [dbo].[V_EMSL_Actual_Usage_By_Category] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EMSL_Actual_Usage_By_Category as
SELECT        dbo.GetFiscalYearFromDate(RunDate) AS FY, Proposal_ID, Category, SUM(Duration) / 60 AS Actual_Hours_Used
FROM            (SELECT        RunDate, Proposal_ID, Category, Duration
                          FROM            (SELECT        TRR.RDS_EUS_Proposal_ID AS Proposal_ID, TD.DS_instrument_name_ID, CASE WHEN TD.Acq_Time_End IS NULL 
                                                                              THEN TD.DS_created ELSE TD.Acq_Time_End END AS RunDate, TZ.Category, ISNULL(DATEDIFF(mi, TD.Acq_Time_Start, TD.Acq_Time_End), 
                                                                              0) AS Duration
                                                    FROM            T_Requested_Run AS TRR INNER JOIN
                                                                              T_Dataset AS TD ON TRR.DatasetID = TD.Dataset_ID INNER JOIN
                                                                                  (SELECT        TIM.DMS_Instrument_ID, CASE WHEN TEI.Local_Category_Name IS NULL 
                                                                                                              THEN TEI.EUS_Display_Name ELSE TEI.Local_Category_Name END AS Category
                                                                                    FROM            T_EMSL_DMS_Instrument_Mapping AS TIM INNER JOIN
                                                                                                              T_EMSL_Instruments AS TEI ON TIM.EUS_Instrument_ID = TEI.EUS_Instrument_ID) AS TZ ON 
                                                                              TZ.DMS_Instrument_ID = TD.DS_instrument_name_ID
                                                    WHERE        (TRR.RDS_EUS_Proposal_ID IS NOT NULL) AND (TD.DS_state_ID = 3)) AS TX) AS TQ
GROUP BY dbo.GetFiscalYearFromDate(RunDate), Proposal_ID, Category
GO
GRANT VIEW DEFINITION ON [dbo].[V_EMSL_Actual_Usage_By_Category] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EMSL_Actual_Usage_By_Category] TO [PNL\D3M580] AS [dbo]
GO
