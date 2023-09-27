/****** Object:  View [dbo].[V_Data_Package_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_Export] AS
SELECT TD.Data_Pkg_ID,
       TD.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       InstName.IN_Name AS Instrument,
       DS.DS_Created AS Created,
       TD.Item_Added,
       TD.Package_Comment,
       TD.Data_Pkg_ID AS Data_Package_ID
FROM T_Data_Package_Datasets TD
     INNER JOIN S_Dataset DS
       ON TD.Dataset_ID = DS.Dataset_ID
     INNER JOIN S_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN S_Experiment_List E
       ON DS.Exp_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Dataset_Export] TO [DDL_Viewer] AS [dbo]
GO
