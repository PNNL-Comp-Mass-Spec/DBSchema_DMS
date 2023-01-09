/****** Object:  View [dbo].[V_DMS_Data_Packages] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_DMS_Data_Packages]
AS
SELECT id,
       name,
       package_type,
       description,
       comment,
       owner,
       requester,
       team,
       created,
       last_modified,
       state,
       package_file_folder,
       share_path,
       web_path,
       amt_tag_database,
       biomaterial_count,
       experiment_count,
       eus_proposal_count,
       dataset_count,
       analysis_job_count,
       total_item_count,
       prism_wiki
FROM S_Data_Package_Details


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Data_Packages] TO [DDL_Viewer] AS [dbo]
GO
