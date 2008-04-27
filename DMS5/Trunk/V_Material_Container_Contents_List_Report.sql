/****** Object:  View [dbo].[V_Material_Container_Contents_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  V_Material_Container_Contents_List_Report AS  
SELECT     T_Material_Containers.Tag AS Container, T_Material_Containers.Type, T.Item_Type, T.Item
FROM         T_Material_Containers INNER JOIN
                          (SELECT     T_Cell_Culture_1.CC_Name AS Item, 'Biomaterial' AS Item_Type, T_Cell_Culture.CC_Container_ID AS C_ID
                            FROM          T_Cell_Culture INNER JOIN
                                                   T_Cell_Culture AS T_Cell_Culture_1 ON T_Cell_Culture.CC_ID = T_Cell_Culture_1.CC_ID
                            UNION
                            SELECT     T_Experiments_1.Experiment_Num AS Item, 'Experiment' AS Item_Type, T_Experiments.EX_Container_ID AS C_ID
                            FROM         T_Experiments INNER JOIN
                                                  T_Experiments AS T_Experiments_1 ON T_Experiments.Exp_ID = T_Experiments_1.Exp_ID) AS T ON T.C_ID = T_Material_Containers.ID
GO
