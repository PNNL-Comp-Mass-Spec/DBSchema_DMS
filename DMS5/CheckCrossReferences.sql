/****** Object:  StoredProcedure [dbo].[CheckCrossReferences] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure CheckCrossReferences
As
	set nocount on


	print 'User PRN in T_Dataset not in T_User'
	--
	SELECT T_Dataset.Dataset_Num, T_Dataset.DS_Oper_PRN 
	FROM T_Dataset 
	WHERE T_Dataset.DS_Oper_PRN 
	NOT IN (SELECT U_PRN FROM T_Users)


	print 'User PRN in T_Experiments not in T_User'
	--
	SELECT T_Experiments.Experiment_Num, T_Experiments.EX_researcher_PRN 
	FROM T_Experiments 
	WHERE (T_Experiments.EX_researcher_PRN 
	NOT IN (SELECT U_PRN FROM T_Users))

	return
GO
GRANT VIEW DEFINITION ON [dbo].[CheckCrossReferences] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckCrossReferences] TO [Limited_Table_Write] AS [dbo]
GO
