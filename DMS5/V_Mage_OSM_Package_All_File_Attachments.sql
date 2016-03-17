/****** Object:  View [dbo].[V_Mage_OSM_Package_All_File_Attachments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Mage_OSM_Package_All_File_Attachments AS 
SELECT  TFA.File_Name ,
        '[Archive_Root_Path]/' + TFA.Archive_Folder_Path AS Archive_Folder_Path,
        TFA.File_Size_Bytes ,
        TFA.Description ,
        TFA.Entity_Type ,
        TFA.Entity_ID ,
        TFA.ID AS FID,
        TPK.OSM_Package_ID
FROM    T_File_Attachment AS TFA
        INNER JOIN ( SELECT OSM_Package_ID ,
                            CASE WHEN Item_Type IN ( 'Sample_Prep_Requests',
                                                     'Experiment_Groups',
                                                     'HPLC_Runs',
                                                     'Sample_Submissions' )
                                 THEN CONVERT(VARCHAR(128), Item_ID)
                                 ELSE CONVERT(VARCHAR(128), ISNULL(Item, ''))
                            END AS Attachment_ID ,
                            CASE WHEN Item_Type = 'Biomaterial'
                                 THEN 'campaign'
                                 WHEN Item_Type = 'Campaign'
                                 THEN 'cell_culture'
                                 WHEN Item_Type = 'Experiment_Groups'
                                 THEN 'experiment_group'
                                 WHEN Item_Type = 'Experiments'
                                 THEN 'experiment'
                                 WHEN Item_Type = 'HPLC_Runs'
                                 THEN 'experiment_group'
                                 WHEN Item_Type = 'Material_Containers'
                                 THEN 'material_container'
                                 WHEN Item_Type = 'Sample_Prep_Requests'
                                 THEN 'sample_prep_request'
                                 WHEN Item_Type = 'Sample_Submissions'
                                 THEN 'sample_submission'
                                 ELSE '???'
                            END AS Item_Type ,
                            Item_ID ,
                            Item
                     FROM   S_V_OSM_Package_Items_Export
                     UNION
                     SELECT  ID AS OSM_Package_ID,
							CONVERT(VARCHAR(128), ID) AS Attchment_ID,
							'osm_package' AS Item_Type,
							ID AS Item_ID,
							Name AS Item
					FROM    S_V_OSM_Package_Export                     
                   ) AS TPK ON TFA.Entity_ID = TPK.Attachment_ID
                               AND TFA.Entity_Type = TPK.Item_Type
WHERE   ( TFA.Active > 0 )
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_OSM_Package_All_File_Attachments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_OSM_Package_All_File_Attachments] TO [PNL\D3M580] AS [dbo]
GO
