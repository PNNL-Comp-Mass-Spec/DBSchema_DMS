/****** Object:  View [dbo].[V_Ext_Experiment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Ext_Experiment_List_Report]
AS
SELECT  E.Exp_ID AS ID, 
       'x' as Sel,
		E.Experiment_Num AS Experiment, 
		U.U_Name + ' (' + E.EX_researcher_PRN + ')' AS Researcher, 
		O.OG_name AS Organism, 
		E.EX_reason AS Reason, 
		E.EX_comment AS Comment, 
		E.EX_sample_concentration AS Concentration, 
		E.EX_created AS Created, 
		C.Campaign_Num AS Campaign, 
		E.EX_cell_culture_list AS [Cell Cultures], 
		EN.Enzyme_Name AS Enzyme, 
		E.EX_lab_notebook_ref AS Notebook, 
		E.EX_Labelling AS Labelling, 
		I.Name AS Predigest, 
		IS1.Name AS Postdigest, 
		E.EX_sample_prep_request_ID AS Request, 
		m.Group_ID
FROM    T_Experiments E
		JOIN T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID 
		JOIN T_Users U ON E.EX_researcher_PRN = U.U_PRN 
		JOIN T_Enzymes EN ON E.EX_enzyme_ID = EN.Enzyme_ID 
		JOIN T_Internal_Standards I ON E.EX_internal_standard_ID = I.Internal_Std_Mix_ID 
		JOIN T_Internal_Standards AS IS1 ON E.EX_postdigest_internal_std_ID = IS1.Internal_Std_Mix_ID 
		JOIN T_Organisms O ON E.EX_organism_ID = O.Organism_ID 
		LEFT JOIN (
				SELECT EGM.Exp_ID, EGM.Group_ID
				FROM  T_Experiment_Group_Members EGM
					JOIN T_Experiment_Groups EG ON EGM.Group_ID = EG.Group_ID
				) AS m ON m.Exp_ID = E.Exp_ID
WHERE EXISTS
		(
			SELECT 1
			FROM T_Experiments EX1
				JOIN T_Dataset D ON D.Exp_ID = EX1.Exp_ID 
				JOIN T_Dataset_Archive DSA ON DSA.AS_Dataset_ID = D.Dataset_ID 
				JOIN T_DatasetArchiveStateName DSN ON DSN.DASN_StateID = DSA.AS_state_ID AND DSN.DASN_StateName = 'Complete'
			WHERE E.Exp_ID = EX1.Exp_ID
		)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Experiment_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Experiment_List_Report] TO [PNL\D3M580] AS [dbo]
GO
