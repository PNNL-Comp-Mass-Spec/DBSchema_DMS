/****** Object:  View [dbo].[V_Analysis_Job_Requests_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Requests_Recent] 
AS
SELECT request,
       name,
       state,
       requester,
       created,
       tool,
       jobs,
       param_file,
       settings_file,
       organism,
       organism_db_file,
       protein_collection_list,
       protein_options,
       datasets,
       data_package,
       comment
FROM V_Analysis_Job_Request_List_Report
WHERE State = 'new' OR
      Created >= DateAdd(day, -5, GetDate())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Requests_Recent] TO [DDL_Viewer] AS [dbo]
GO
