/****** Object:  View [dbo].[V_Experiment_Groups_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Experiment_Groups_List_Report as
SELECT        T_Experiment_Groups.Group_ID AS ID, T_Experiment_Groups.EG_Group_Type AS Group_Type, T_Experiment_Groups.Tab, 
                         T_Experiment_Groups.EG_Description AS Description, COUNT(T_Experiment_Group_Members.Exp_ID) AS Members, TA.Attachments AS Files, 
                         T_Experiments.Experiment_Num AS Parent_Experiment, T_Experiment_Groups.EG_Created AS Created, CASE WHEN T_Experiment_Groups.Researcher IS NULL 
                         THEN '' ELSE T_Users.U_Name + ' (' + T_Users.U_PRN + ')' END AS Researcher
FROM            T_Experiment_Groups LEFT OUTER JOIN
                         T_Experiment_Group_Members ON T_Experiment_Groups.Group_ID = T_Experiment_Group_Members.Group_ID INNER JOIN
                         T_Experiments ON T_Experiment_Groups.Parent_Exp_ID = T_Experiments.Exp_ID LEFT OUTER JOIN
                             (SELECT        Entity_ID AS [Entity ID], COUNT(*) AS Attachments
                               FROM            T_File_Attachment
                               WHERE        (Entity_Type = 'experiment_group')
                               GROUP BY Entity_ID) AS TA ON T_Experiment_Groups.Group_ID = TA.[Entity ID] LEFT OUTER JOIN
                         T_Users ON T_Experiment_Groups.Researcher = T_Users.U_PRN
GROUP BY T_Experiment_Groups.Group_ID, T_Experiment_Groups.EG_Group_Type, T_Experiment_Groups.EG_Description, T_Experiment_Groups.EG_Created, 
                         T_Experiments.Experiment_Num, CASE WHEN T_Experiment_Groups.Researcher IS NULL THEN '' ELSE T_Users.U_Name + ' (' + T_Users.U_PRN + ')' END, 
                         T_Experiment_Groups.Tab, TA.Attachments        

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_List_Report] TO [PNL\D3M580] AS [dbo]
GO
