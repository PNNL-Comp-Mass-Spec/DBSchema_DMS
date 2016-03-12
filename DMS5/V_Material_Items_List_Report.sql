/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Items_List_Report]
AS
SELECT T.Item,
       T.Item_Type,
       T.Item_ID AS ID,
	   T.Barcode,
       MC.Tag AS Container,
       MC.[Type],
       SUBSTRING(T.Item_Type, 1, 1) + ':' + CONVERT(varchar, T.Item_ID) AS [#I_ID],
       ML.Tag AS Location
FROM dbo.T_Material_Containers AS MC
     INNER JOIN (SELECT Experiment_Num AS Item,
                        'Experiment' AS Item_Type,
                        EX_Container_ID AS C_ID,
                        Exp_ID AS Item_ID,
						EX_Barcode As Barcode
                 FROM dbo.T_Experiments 
				 UNION
				 SELECT CC_Name AS Item,
                        'Biomaterial' AS Item_Type,
                        CC_Container_ID AS C_ID,
                        CC_ID AS Item_ID,
						Null As Barcode
                 FROM dbo.T_Cell_Culture                 
				 ) AS T
       ON T.C_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations AS ML
       ON MC.Location_ID = ML.ID
WHERE (MC.Status = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Items_List_Report] TO [PNL\D3M578] AS [dbo]
GO
