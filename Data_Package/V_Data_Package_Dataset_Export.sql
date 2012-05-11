/****** Object:  View [dbo].[V_Data_Package_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Data_Package_Dataset_Export AS 
SELECT     Data_Package_ID, Dataset_ID, Dataset, Experiment, Instrument, Created, [Item Added], [Package Comment]
FROM         T_Data_Package_Datasets
GO
