/****** Object:  View [dbo].[V_OSM_Package_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_OSM_Package_Entry]
AS
SELECT
	id,
	name,
	package_type,
	description,
	keywords,
	comment,
	owner,
	[state],
	Sample_Prep_Requests AS sample_prep_request_list,
	user_folder_path
FROM T_OSM_Package
GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_Entry] TO [DDL_Viewer] AS [dbo]
GO
