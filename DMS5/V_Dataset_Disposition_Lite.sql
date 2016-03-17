/****** Object:  View [dbo].[V_Dataset_Disposition_Lite] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Dataset_Disposition_Lite] as
SELECT ID,
       [Sel.],
       Dataset,
       SMAQC,
       [LC Cart],
       Batch,
       Request,
       Rating,
       [Comment],
       State,
       Instrument,
       Created,
       [Oper.]
FROM V_Dataset_Disposition


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition_Lite] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition_Lite] TO [PNL\D3M580] AS [dbo]
GO
