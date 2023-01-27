/****** Object:  View [dbo].[V_Bionet_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_Entry]
AS
SELECT host,
       ip,
       alias,
       entered,
       last_online,
       instruments,
       active,
       tag,
       comment
FROM T_Bionet_Hosts


GO
