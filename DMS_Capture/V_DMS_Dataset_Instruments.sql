/****** Object:  View [dbo].[V_DMS_Dataset_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Dataset_Instruments
AS
SELECT D.Dataset_ID,
              D.Dataset_Num AS Dataset,
              D.Acq_Time_Start,
              I.IN_Name AS Instrument
FROM S_DMS_T_Instrument_Name I
     INNER JOIN S_DMS_T_Dataset D
       ON D.DS_instrument_name_ID = I.Instrument_ID

GO
