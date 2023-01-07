/****** Object:  View [dbo].[V_Dataset_Disposition_Lite] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Disposition_Lite]
AS
SELECT id,
       sel,
       dataset,
       smaqc,
       lc_cart,
       batch,
       request,
       rating,
       comment,
       state,
       instrument,
       created,
       operator
FROM V_Dataset_Disposition


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition_Lite] TO [DDL_Viewer] AS [dbo]
GO
