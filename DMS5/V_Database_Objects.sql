/****** Object:  View [dbo].[V_Database_Objects] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Database_Objects AS 
SELECT
  name AS Name,
  type_desc AS Type,
  CONVERT(VARCHAR(24), object_id) AS ID,
  modify_date AS Modified,
  create_date AS Created
FROM
  sys.objects
WHERE
  ( type IN ( 'T', 'V', 'P', 'U', 'FN' ) )
  AND ( NOT ( name LIKE N'dt_%' )
      )                                                                                                                                                                                                                                                       

GO
GRANT VIEW DEFINITION ON [dbo].[V_Database_Objects] TO [PNL\D3M578] AS [dbo]
GO
