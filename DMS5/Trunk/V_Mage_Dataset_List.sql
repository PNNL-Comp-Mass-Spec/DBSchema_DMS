/****** Object:  View [dbo].[V_Mage_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Mage_Dataset_List AS 
SELECT     ID AS Dataset_ID, Dataset, Experiment, Campaign, State, Instrument, Created, [Dataset Type] AS Type, [Archive Folder Path] AS Folder, Comment
FROM         V_Dataset_List_Report_2

GO
