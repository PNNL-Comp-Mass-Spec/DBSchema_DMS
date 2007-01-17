/****** Object:  View [dbo].[V_Predefined_Analysis_Dataset_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Predefined_Analysis_Dataset_Info
AS
SELECT     Cmpgn.Campaign_Num AS Campaign, Exp.Experiment_Num AS Experiment, Exp.EX_comment AS Experiment_Comment, 
                      Exp.EX_Labelling AS Experiment_Labelling, dbo.T_Organisms.OG_name AS Organism, InstName.IN_name AS Instrument, 
                      InstName.IN_class AS InstrumentClass, DS.DS_comment AS Dataset_Comment, DS.Dataset_ID AS ID, DS.Dataset_Num AS Dataset, 
                      DS.DS_rating AS Rating, DSTypeName.DST_name AS Dataset_Type
FROM         dbo.T_Dataset DS INNER JOIN
                      dbo.T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
                      dbo.T_Experiments Exp ON DS.Exp_ID = Exp.Exp_ID INNER JOIN
                      dbo.T_Campaign Cmpgn ON Exp.EX_campaign_ID = Cmpgn.Campaign_ID INNER JOIN
                      dbo.T_DatasetTypeName DSTypeName ON DS.DS_type_ID = DSTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Organisms ON Exp.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO
