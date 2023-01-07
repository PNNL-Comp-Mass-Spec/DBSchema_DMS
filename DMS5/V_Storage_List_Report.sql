/****** Object:  View [dbo].[V_Storage_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_List_Report]
AS
SELECT SPath.SP_path_ID AS id,
       SPath.SP_path AS storage_path,
       SPath.SP_vol_name_client AS vol_client,
       SPath.SP_vol_name_server AS vol_server,
       SPath.SP_function AS storage_path_function,
       SPath.SP_instrument_name AS instrument,
       COUNT(DS.Dataset_ID) AS datasets,
       SPath.SP_description AS description,
       SPath.SP_Created AS created
FROM dbo.t_storage_path SPath
     LEFT OUTER JOIN dbo.T_Dataset DS
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
GROUP BY SPath.SP_path_ID, SPath.SP_path, SPath.SP_vol_name_client,
         SPath.SP_vol_name_server, SPath.SP_function,
         SPath.SP_instrument_name, SPath.SP_description, SPath.SP_Created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_List_Report] TO [DDL_Viewer] AS [dbo]
GO
