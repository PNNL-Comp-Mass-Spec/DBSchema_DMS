/****** Object:  View [dbo].[V_Material_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Items_List_Report
AS
SELECT     T.Item, T.Item_Type, dbo.T_Material_Containers.Tag AS Container, dbo.T_Material_Containers.Type, SUBSTRING(T.Item_Type, 1, 1) 
                      + ':' + CONVERT(varchar, T.Item_ID) AS [#I_ID], dbo.T_Material_Locations.Tag AS Location
FROM         dbo.T_Material_Containers INNER JOIN
                          (SELECT     T_Cell_Culture_1.CC_Name AS Item, 'Biomaterial' AS Item_Type, dbo.T_Cell_Culture.CC_Container_ID AS C_ID, 
                                                   dbo.T_Cell_Culture.CC_ID AS Item_ID
                            FROM          dbo.T_Cell_Culture INNER JOIN
                                                   dbo.T_Cell_Culture AS T_Cell_Culture_1 ON dbo.T_Cell_Culture.CC_ID = T_Cell_Culture_1.CC_ID
                            UNION
                            SELECT     T_Experiments_1.Experiment_Num AS Item, 'Experiment' AS Item_Type, dbo.T_Experiments.EX_Container_ID AS C_ID, 
                                                  dbo.T_Experiments.Exp_ID AS Item_ID
                            FROM         dbo.T_Experiments INNER JOIN
                                                  dbo.T_Experiments AS T_Experiments_1 ON dbo.T_Experiments.Exp_ID = T_Experiments_1.Exp_ID) AS T ON 
                      T.C_ID = dbo.T_Material_Containers.ID INNER JOIN
                      dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID
WHERE     (dbo.T_Material_Containers.Status = 'Active')

GO
